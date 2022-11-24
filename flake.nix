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
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
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
            settings = {
              layout = "us";
              videoDrivers = ["nvidia"];
              hardware = ./hardware/desktop.nix;
            };
            # settings = {
            #   layout = "no";
            #   videoDrivers = [];
            #   hardware = ./hardware/laptop.nix;
            # };
          in {
            imports = [
              settings.hardware
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
                    rev = "a071d3e648e146b3f8663d4b86b33f5e47ccefab";
                    sha256 = "epPYG2Ju4mEsniW32v7E3jZSiZk3u008mZdMR44+5gE=";
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
            services.xserver.videoDrivers = settings.videoDrivers;
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

            # Enable cron service
            services.cron = {
              enable = true;
              systemCronJobs = [
                "*/5 * * * * odd ${pkgs.isync}/bin/mbsync -a; ${pkgs.notmuch}/bin/notmuch new"
              ];
            };

            # GnuPG
            programs.gnupg.agent = {
              enable = true;
              enableSSHSupport = true;
              pinentryFlavor = "gnome3";
            };

            # Don't use that ugly GUI program for password
            programs.ssh.askPassword = "";
            
            # autojump
            programs.autojump.enable = true;
            
            
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

            # For direnv
            environment.pathsToLink = [
              "/share/nix-direnv"
            ];
            
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

            # Make sure we're not on powersave
            powerManagement.cpuFreqGovernor = "performance";

            # Configure console keymap
            console.keyMap = "colemak";

            # Docker
            virtualisation.docker.enable = true;

            # Emacs
            services.emacs = {
              enable = true;
              defaultEditor = true;
              package = with pkgs; ((emacsPackagesFor emacs28NativeComp).emacsWithPackages (epkgs: [epkgs.vterm]));
            };

            # Fonts
            fonts.fonts = with pkgs; [
              hack-font
              noto-fonts-emoji
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
              layout = settings.layout;
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
                  sxhkd &
                  xbanish &
                  hsetroot -solid "#f7f3ee"
                '';
              };
            };

            # Environment
            environment = {
              binsh = "${pkgs.dash}/bin/dash";
              systemPackages = with pkgs; [
                fd
                git
                zip
                dig
                file
                tldr
                dash
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
            };

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

                # rust
                (rust-bin.stable.latest.default.override {
                  extensions = ["rust-src"];
                  targets = ["wasm32-wasi" "wasm32-unknown-unknown"];
                })
                mold
                bacon
                cargo-watch
                rust-analyzer
                cargo-nextest

                # zig
                zig
                zls
                qemu

                # c++
                gcc
                ccls

                # nix
                rnix-lsp

                # python
                python310

                # scala
                scala

                # dotnet
                dotnet-sdk

                # elm
                elmPackages.elm
                elmPackages.elm-language-server

                # typescript
                nodePackages.typescript
                nodePackages.typescript-language-server

                # prolog
                swiProlog

                # latex
                texlive.combined.scheme-full

                # work
                wasmer
                docker-compose

                # hacking
                nmap
                john
                sqlmap
                thc-hydra

                # email
                isync
                msmtp
                notmuch

                # finance
                ledger

                # bash
                fzf
                starship

                # hacking
                zap
                wmname
                metasploit
                burpsuite

                # other
                xxd
                mpv
                zeal
                zoom
                gimp
                entr
                ncdu
                zola
                scrot
                morph
                sxhkd
                ffmpeg
                firefox
                gnumake
                lxrandr
                openvpn
                bintools
                valgrind
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
