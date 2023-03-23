{
  description = "Knarkzel's NixOS Flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
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
    };
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
    };
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    emacs-overlay,
    zig-overlay,
    ...
  }: {
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
              url = "https://raw.githubusercontent.com/StevenBlack/hosts/6d4674abda33850fb0d0b7ce436e36cdc341b506/alternates/fakenews-gambling-porn/hosts";
              sha256 = "18KYiZAZ+yrcDIOoBWWURrePWKHScAd9gq25UegC2TU=";
            };
            extra = ''
              0.0.0.0 animedao.to
              0.0.0.0 tiktok.com
              0.0.0.0 lobste.rs
              0.0.0.0 news.ycombinator.com
            '';
            desktop = {
              layout = "us";
              videoDrivers = ["nvidia"];
              hardware = ./hardware/desktop.nix;
              bootLoader = {
                grub.enable = true;
                grub.device = "/dev/sda";
                grub.useOSProber = true;
              };
            };
            thinkpad = {
              layout = "no";
              videoDrivers = [];
              hardware = ./hardware/thinkpad.nix;
              bootLoader = {
                grub.enable = true;
                grub.device = "/dev/sda";
                grub.useOSProber = true;
              };
            };
            hp = {
              layout = "no";
              videoDrivers = [];
              hardware = ./hardware/hp.nix;
              bootLoader = {
                systemd-boot.enable = true;
                efi.canTouchEfiVariables = true;
              };
            };
            settings = desktop;
          in {
            # System config
            system.stateVersion = "22.11";

            imports = [
              settings.hardware
            ];

            nixpkgs.overlays = [
              # latest emacs
              emacs-overlay.overlays.default
              
              # rust
              rust-overlay.overlays.default

              # zig
              zig-overlay.overlays.default
              
              # dwm
              (final: prev: {
                dwm = prev.dwm.overrideAttrs (drv: {
                  src = prev.fetchFromSourcehut {
                    owner = "~knarkzel";
                    repo = "dwm";
                    rev = "812b3101f65da147752101a0560ac65b3c6703cd";
                    sha256 = "SQ8cxjFWZl2jGOjg8iUUc7YEstmZWKwY0tafwSsnUKA=";
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
            boot.loader = settings.bootLoader;

            # Enable networking
            networking.hostName = "odd";
            networking.firewall.enable = true;
            networking.networkmanager.enable = true;
            networking.nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
            networking.extraHosts = (builtins.readFile hosts) + extra;

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

            # ZRam
            zramSwap = {
              enable = true;
              memoryPercent = 100;
            };
            
            # Bluetooth
            hardware.bluetooth.enable = true;
            services.blueman.enable = true;

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

            # Work
            virtualisation.docker.enable = true;
              
            # Emacs
            services.emacs = {
              enable = true;
              defaultEditor = true;
              package = with pkgs; ((emacsPackagesFor emacsGit).emacsWithPackages (epkgs: [epkgs.vterm]));
            };

            # Fonts
            fonts.fonts = with pkgs; [
              hack-font
              noto-fonts
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
                interception-tools
              ];
            };

            # Define user account.
            users.users.odd = {
              isNormalUser = true;
              description = "Odd-Harald";
              extraGroups = ["networkmanager" "wheel" "docker" "transmission" "dialout"];

              packages = with pkgs; [
                # window manager
                dmenu
                dunst
                xbanish
                hsetroot

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
                cargo-expand
                cargo-wasi
                wasmtime
                
                # zig
                zigpkgs.master
                zls
                qemu

                # c++
                gcc
                ccls

                # python
                (python310.withPackages(pypkgs: [ pypkgs.openai ]))

                  
                # dotnet
                dotnet-sdk

                # typescript
                nodejs                
                nodePackages.npm                
                nodePackages.typescript
                nodePackages.typescript-language-server

                # latex
                texlive.combined.scheme-full

                # work
                wabt
                wasmer
                binaryen
                docker-compose

                # bash
                fzf
                starship

                # video
                mpv
                xclip
                yt-dlp

                # octave
                (octave.withPackages (pkgs: [ pkgs.symbolic ]))

                # other
                bun
                xxd
                gimp
                ncdu
                scrot
                morph
                sxhkd
                ffmpeg
                bottom
                brave
                ripcord
                gnumake
                lxrandr
                openvpn
                bintools
                alacritty
                imagemagick
                libreoffice
                stalonetray
                networkmanagerapplet
                openai
              ];
            };
          }
        )
      ];
    };
  };
}
