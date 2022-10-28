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
    zig-nightly = {
      url = "github:chivay/zig-nightly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    zig-nightly,
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
              url = "https://raw.githubusercontent.com/StevenBlack/hosts/2924bf615ccd07e49f47550f78d8c2aeee4c0e7b/alternates/fakenews-gambling-porn-social/hosts";
              sha256 = "yQrr9+Co8KAsE1pl3kayEQYFTqgeekPZrcT5Ni2eYkg=";
            };
          in {
            imports = [
              ./hardware/desktop.nix
              ./cachix.nix
            ];

            nixpkgs.overlays = [
              # rust
              rust-overlay.overlays.default

              # dwm
              (final: prev: {
                dwm = prev.dwm.overrideAttrs (drv: {
                  src = prev.fetchFromSourcehut {
                    owner = "~knarkzel";
                    repo = "dwm";
                    rev = "1bfa906a9f657c5ab2f1333ca8ba2e4f2a17aed4";
                    sha256 = "0e3rTugz98pqe1FtfpfqiXygrCWLgJwEZ10AkOAnDSc=";
                  };
                });
              })

              # dmenu
              (final: prev: {
                dmenu = prev.dmenu.overrideAttrs (drv: {
                  src = prev.fetchFromSourcehut {
                    owner = "~knarkzel";
                    repo = "dmenu";
                    rev = "b6a57bf5e771fcf0dd8df27cc1930d807cfed173";
                    sha256 = "aMpKlMNlW4aUylv3FrozgtTFNwlMaaaAzs56/F16ZyY=";
                  };
                });
              })

              # bitlbee-discord
              (final: prev: {
                bitlbee-discord = prev.bitlbee-discord.overrideAttrs (drv: {
                  src = prev.fetchFromGitHub {
                    owner = "sm00th";
                    repo = "bitlbee-discord";
                    rev = "607f9887ca85f246e970778e3d40aa5c346365a7";
                    sha256 = "h3Wrd0dCzyOHGkBrMHrJBOMgAR6hJ7aBV6JTxUWHfEo=";
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
            hardware.opengl = {
              enable = true;
              extraPackages = with pkgs; [
                vaapiIntel
                vaapiVdpau
                libvdpau-va-gl
                intel-media-driver
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

            # GnuPG
            programs.gnupg.agent = {                                                      
              enable = true;
              enableSSHSupport = true;
              pinentryFlavor = "gnome3";
            };

            # Enable cron service
            services.cron = {
              enable = true;
              systemCronJobs = [
                "*/5 * * * * odd ${pkgs.isync}/bin/mbsync -a; ${pkgs.notmuch}/bin/notmuch new"
              ];
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
            
            # Disable cursor while typing
            services.xbanish.enable = true;

            # IRC gateway
            nixpkgs.config.bitlbee.enableLibPurple = true;
            services.bitlbee = {
              enable = true;
              plugins = [
                pkgs.bitlbee-discord
              ];
              libpurple_plugins = [
                pkgs.purple-slack
              ];
            };
            
            # Don't use that ugly GUI program for password
            programs.ssh.askPassword = "";

            # Make sure we're not on powersave
            powerManagement.cpuFreqGovernor = "performance";

            # Configure console keymap
            console.keyMap = "colemak";

            # Docker
            virtualisation.docker.enable = true;

            # Fonts
            fonts.fonts = with pkgs; [
              hack-font
              noto-fonts-emoji
            ];

            # For direnv
            environment.pathsToLink = [
              "/share/nix-direnv"
            ];
            
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
                    EVENTS:
                      EV_KEY: [[KEY_CAPSLOCK, KEY_ESC, KEY_LEFTCTRL]]
              '';
            };

            # Configure X11
            services.xserver = {
              enable = true;
              layout = "us";
              xkbVariant = "colemak";
              windowManager.dwm.enable = true;
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
                  hsetroot -solid "#f7f3ee"
                '';
              };
            };
            
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
              ripgrep
              e2fsprogs
              dosfstools
              nix-direnv
              libimobiledevice
              omnisharp-roslyn
              interception-tools
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
                hsetroot

                # emacs
                ((emacsPackagesFor emacs28NativeComp).emacsWithPackages (epkgs: [epkgs.vterm]))

                # finance
                ledger

                # rust
                (rust-bin.nightly.latest.default.override {
                  extensions = ["rust-src"];
                  targets = ["wasm32-wasi" "wasm32-unknown-unknown"];
                })
                mold
                bacon
                cargo-watch
                rust-analyzer
                cargo-nextest

                # zig
                zig-nightly.packages.${system}.zig-nightly
                zls
                qemu

                # c++
                gcc
                ccls
                
                # nix
                cachix
                rnix-lsp

                # python
                python310

                # scala
                dotty
                metals

                # dotnet
                dotnet-sdk

                # typescript
                nodePackages.typescript
                nodePackages.typescript-language-server
                
                # prolog
                swiProlog

                # latex
                texlive.combined.scheme-full
                
                # work
                docker-compose

                # hacking
                nmap
                john

                # email
                pass
                isync
                msmtp
                notmuch
                
                # other
                xxd
                mpv
                zeal
                gimp
                entr
                ncdu
                zola
                scrot
                morph
                ffmpeg
                firefox
                gnumake
                lxrandr
                starship
                alacritty
                imagemagick
                libreoffice
              ];
            };
          }
        )
      ];
    };
  };
}
