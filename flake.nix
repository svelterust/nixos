{
  description = "Knarkzel's NixOS Flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-22.05";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    emacs-overlay,
    ...
  } @ inputs: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    nixosConfigurations."odd" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (
          {
            config,
            pkgs,
            lib,
            ...
          }: let
            hosts = pkgs.fetchurl {
              url = "https://git.sr.ht/~knarkzel/block/blob/f92546c1466a5ce27717aedb05348a01707a680d/hosts";
              sha256 = "NK5Vbr8zQVm/e1dVMNl/IrD8wydZG5vB2zeXdV/lvRI=";
            };
          in {
            imports = [
              ./hardware-configuration.nix
            ];

            nixpkgs.overlays = [
              # rust
              rust-overlay.overlays.default

              # emacs
              emacs-overlay.overlay

              # dwm
              (final: prev: {
                dwm = prev.dwm.overrideAttrs (drv: {
                  src = prev.fetchFromSourcehut {
                    owner = "~knarkzel";
                    repo = "dwm";
                    rev = "a91eb88ce69cdaf67413faba4251e89e0e08348f";
                    sha256 = "NOOuiNFSC1BOZiF73ZM63+VrJYaa3wUg716Pho0M+SY=";
                  };
                });
              })

              # dmenu
              (final: prev: {
                dmenu = prev.dmenu.overrideAttrs (drv: {
                  src = prev.fetchFromSourcehut {
                    owner = "~knarkzel";
                    repo = "dmenu";
                    rev = "37903c99818426f4c913fbcc59fa23c84b206f54";
                    sha256 = "FECWdptTxU1ZZnBDMG3onnKv31X7noEaunI1FnP+8HA=";
                  };
                });
              })
            ];

            # Bootloader.
            boot.loader.grub.enable = true;
            boot.loader.grub.device = "/dev/sda";
            boot.loader.grub.useOSProber = true;

            # Enable networking
            networking.hostName = "odd";
            networking.firewall.enable = true;
            networking.networkmanager.enable = true;
            networking.nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
            networking.extraHosts = builtins.readFile hosts;

            # Set your time zone.
            time.timeZone = "Europe/Oslo";

            # Select internationalisation properties.
            i18n.defaultLocale = "en_US.utf8";

            # Enable iPhone tethering
            services.usbmuxd.enable = true;

            # Configure graphics
            services.xserver.videoDrivers = ["nvidia"];
            nixpkgs.config.packageOverrides = pkgs: {
              vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
            };
            hardware.opengl = {
              enable = true;
              extraPackages = with pkgs; [
                intel-media-driver
                vaapiIntel
                vaapiVdpau
                libvdpau-va-gl
              ];
            };

            # Location for redshift
            location = {
              latitude = 58.0;
              longitude = 9.0;
            };

            # Configure redshift
            services.redshift = {
              enable = true;
              brightness = {
                day = "1.0";
                night = "0.6";
              };
              temperature = {
                day = 6500;
                night = 2000;
              };
            };

            # Enable sound with pipewire.
            sound.enable = true;
            hardware.pulseaudio.enable = false;
            security.rtkit.enable = true;
            services.pipewire = {
              enable = true;
              alsa.enable = true;
              alsa.support32Bit = true;
              pulse.enable = true;
              jack.enable = true;
            };

            # Bluetooth
            hardware.bluetooth.enable = true;
            services.blueman.enable = true;

            # System config
            system.stateVersion = "22.05";

            # Allow unfree packages
            nixpkgs.config.allowUnfree = true;

            # Allow experimental features
            nix.extraOptions = ''
              experimental-features = nix-command flakes
              keep-outputs = true
              keep-derivations = true
            '';

            # Don't use that ugly GUI program for password
            programs.ssh.askPassword = "";

            # Make sure we're not on powersave
            powerManagement.cpuFreqGovernor = "performance";

            # Configure console keymap
            console.keyMap = "colemak";

            # Docker
            virtualisation.docker.enable = true;

            # Postgresql
            services.postgresql.enable = true;

            # Transmission
            services.transmission.enable = true;

            # Capslock as Control + Escape everywhere
            services.interception-tools = let
              dfkConfig = pkgs.writeText "dual-function-keys.yaml" ''
                MAPPINGS:
                  - KEY: KEY_CAPSLOCK
                    TAP: KEY_ESC
                    HOLD: KEY_LEFTCTRL
              '';
            in {
              enable = true;
              plugins = lib.mkForce [
                pkgs.interception-tools-plugins.dual-function-keys
              ];
              udevmonConfig = ''
                - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c ${dfkConfig} | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
                  DEVICE:
                    NAME: "Kinesis Advantage2 Keyboard"
                    EVENTS:
                      EV_KEY: [[KEY_CAPSLOCK, KEY_ESC, KEY_LEFTCTRL]]
              '';
            };

            # Configure X11
            services.xserver = {
              enable = true;
              windowManager.dwm.enable = true;
              layout = "us";
              xkbVariant = "colemak";
              libinput = {
                enable = true;
                mouse.accelSpeed = "0";
              };
              displayManager = {
                autoLogin.enable = true;
                autoLogin.user = "odd";
                sessionCommands = ''
                  xset -dpms
                  xset s off
                  xset r rate 200 50
                  dunst &
                  xbanish &
                  hsetroot -solid "#f7f3ee"
                '';
              };
            };

            # Fonts
            fonts.fonts = with pkgs; [
              hack-font
              noto-fonts-emoji
            ];

            # System packages
            environment.systemPackages = with pkgs; [
              fd
              git
              zip
              dig
              file
              tldr
              unzip
              clang
              p7zip
              psmisc
              direnv
              git-lfs
              ripgrep
              e2fsprogs
              dosfstools
              nix-direnv
              libimobiledevice
              omnisharp-roslyn
              interception-tools
            ];

            # For direnv
            environment.pathsToLink = [
              "/share/nix-direnv"
            ];

            # Define user account.
            users.users.odd = {
              isNormalUser = true;
              description = "Odd-Harald";
              extraGroups = ["networkmanager" "wheel" "docker" "transmission"];

              packages = with pkgs; [
                # window manager
                dmenu
                dunst
                xbanish
                hsetroot

                # emacs
                ((emacsPackagesFor emacsNativeComp).emacsWithPackages (epkgs: [epkgs.vterm]))

                # rust
                (rust-bin.nightly.latest.default.override {
                  extensions = ["rust-src"];
                  targets = ["wasm32-wasi"];
                })
                mold
                trunk
                diesel-cli
                cargo-diet
                cargo-watch
                cargo-bloat
                cargo-udeps
                cargo-audit
                rust-analyzer
                cargo-nextest
                cargo-outdated

                # zig
                zig
                zls

                # haskell
                ghc
                haskell-language-server

                # typescript
                nodePackages.typescript
                nodePackages.typescript-language-server

                # nix
                rnix-lsp

                # latex
                texlab
                texlive.combined.scheme-full

                # python
                python310
                virtualenv
                python-language-server

                # hacking
                nmap
                amass
                gobuster
                dnsrecon

                # scala
                scala
                metals

                # dotnet
                dotnet-sdk

                # prolog
                swiProlog

                # work
                zoom-us
                postman
                docker-compose

                # other
                xxd
                mpv
                gimp
                ncdu
                zola
                exif
                scrot
                tokei
                morph
                ffmpeg
                blender
                zathura
                firefox
                gnumake
                lxrandr
                starship
                alacritty
                imagemagick
                libreoffice
                emulationstation
                transmission-gtk
              ];
            };

            # Make sure dotfiles exist
            systemd.services.dotfiles = {
              description = "Initializes bare dotfiles repository";
              wantedBy = ["multi-user.target"];
              unitConfig = {
                ConditionPathExists = "!/home/odd/.cfg";
                Requires = "network-online.target";
                After = "network-online.target";
              };
              serviceConfig = {
                Type = "oneshot";
                User = "odd";
                ExecStart = [
                  ''${pkgs.git}/bin/git clone --bare git@git.sr.ht:~knarkzel/dotfiles /home/odd/.cfg''
                  ''${pkgs.git}/bin/git --git-dir=/home/odd/.cfg --work-tree=/home/odd/ checkout -f''
                  ''${pkgs.git}/bin/git --git-dir=/home/odd/.cfg --work-tree=/home/odd/ config status.showUntrackedFiles no''
                  ''${pkgs.coreutils}/bin/mkdir -p /home/odd/downloads''
                  ''${pkgs.coreutils}/bin/mkdir -p /home/odd/source''
                ];
              };
            };
          }
        )
      ];
    };
  };
}
