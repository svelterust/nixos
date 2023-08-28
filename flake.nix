{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
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
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    emacs-overlay,
    home-manager,
    ...
  } @ inputs: {
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
              url = "https://raw.githubusercontent.com/knarkzel/hosts/114607681682ed7257749c7ad3e11c404c13f96b/alternates/fakenews-gambling-porn/hosts";
              sha256 = "xtRzClDbXbW0oYYCdfV8aROzDWVM7zEk94k+oWLVMLw=";
            };
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
            system.stateVersion = "23.11";

            # Set your time zone.
            time.timeZone = "Europe/Oslo";

            # Select internationalisation properties.
            i18n.defaultLocale = "en_US.utf8";

            # Configure console keymap
            console.keyMap = "colemak";

            # Work
            virtualisation.docker.enable = true;

            # Location for redshift
            location = {
              latitude = 58.0;
              longitude = 9.0;
            };

            imports = [
              settings.hardware
              "${home-manager}/nixos"
            ];

            nixpkgs = {
              config.allowUnfree = true;
              overlays = [
                # latest emacs
                emacs-overlay.overlays.default

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
              ];
            };

            # Programs
            programs = {
              ssh.askPassword = "";
            };

            # Bootloader.
            boot = {
              loader = settings.bootLoader;
              supportedFilesystems = ["ntfs"];
            };

            # Enable sound
            sound.enable = true;
            security.rtkit.enable = true;

            # Enable networking
            networking = {
              hostName = "odd";
              firewall.enable = true;
              networkmanager.enable = true;
              extraHosts = builtins.readFile hosts;
              nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
            };

            # Enable OpenGL and bluetooth
            hardware = {
              bluetooth.enable = true;
              opengl = {
                enable = true;
                driSupport = true;
                driSupport32Bit = true;
                extraPackages = with pkgs; [
                  vaapiIntel
                  vaapiVdpau
                  libvdpau-va-gl
                  intel-media-driver
                ];
              };
            };

            # Services
            services = {
              dbus.implementation = "broker";
              teamviewer.enable = true;
              usbmuxd.enable = true;
              blueman.enable = true;
              gnome.gnome-keyring.enable = true;
              xserver = {
                enable = true;
                xkbVariant = "colemak";
                layout = settings.layout;
                videoDrivers = settings.videoDrivers;
                windowManager.dwm.enable = true;
                libinput = {
                  enable = true;
                  mouse.accelSpeed = "0";
                };
                displayManager = {
                  autoLogin.enable = true;
                  autoLogin.user = "odd";
                };
              };
              emacs = {
                enable = true;
                defaultEditor = true;
                package = with pkgs; ((emacsPackagesFor emacs-git).emacsWithPackages (epkgs: [epkgs.vterm]));
              };
              picom = {
                enable = true;
                shadow = true;
                shadowOpacity = 0.25;
              };
              redshift = {
                enable = true;
                brightness = {
                  day = "1.0";
                  night = "0.6";
                };
                temperature = {
                  day = 6500;
                  night = 1250;
                };
              };
              pipewire = {
                enable = true;
                alsa.enable = true;
                alsa.support32Bit = true;
                pulse.enable = true;
                jack.enable = true;
              };
            };

            # Manage nix settings
            nix = {
              nixPath = [
                "nixpkgs=/etc/channels/nixpkgs"
                "nixos-config=/etc/nixos/configuration.nix"
                "/nix/var/nix/profiles/per-user/root/channels"
              ];
              gc = {
                automatic = true;
                dates = "weekly";
                options = "--delete-older-than 7d";
              };
              settings = {
                trusted-users = ["root" "odd"];
                experimental-features = ["nix-command" "flakes"];
                auto-optimise-store = true;
                keep-derivations = true;
                keep-outputs = true;
              };
              registry.nixpkgs.flake = inputs.nixpkgs;
            };

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

            # Fonts
            fonts.packages = with pkgs; [
              hack-font
              noto-fonts
              noto-fonts-emoji
            ];

            # Manage environment
            environment = {
              binsh = "${pkgs.dash}/bin/dash";
              systemPackages = with pkgs; [
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
                alejandra
                e2fsprogs
                dosfstools
                nix-direnv
                libimobiledevice
                interception-tools
              ];
              etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;
              pathsToLink = ["/share/nix-direnv"];
            };

            # Define user account.
            users = {
              defaultUserShell = pkgs.nushell;
              users.odd = {
                isNormalUser = true;
                description = "Odd-Harald";
                extraGroups = ["networkmanager" "wheel" "docker" "dialout"];
              };
            };

            # Manage user account with home manager
            home-manager = {
              users.odd = {
                pkgs,
                config,
                ...
              }: {
                # Overlays
                nixpkgs = {
                  config.allowUnfree = true;
                  overlays = [
                    #rust
                    rust-overlay.overlays.default

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
                };

                # User dirs
                xdg.userDirs = {
                  enable = true;
                  desktop = "${config.home.homeDirectory}";
                  documents = "${config.home.homeDirectory}";
                  download = "${config.home.homeDirectory}/downloads";
                  music = "${config.home.homeDirectory}";
                  pictures = "${config.home.homeDirectory}";
                  publicShare = "${config.home.homeDirectory}";
                  templates = "${config.home.homeDirectory}";
                  videos = "${config.home.homeDirectory}";
                };

                # Fonts
                fonts = {
                  fontconfig.enable = true;
                };

                # Custom dotfiles
                home.file = {
                  ".cargo" = {
                    source = ./dotfiles/cargo;
                    recursive = true;
                  };
                  ".emacs.d" = {
                    source = ./dotfiles/emacs;
                    recursive = true;
                  };
                };

                # Configure programs
                programs = {
                  bat = {
                    enable = true;
                  };

                  direnv = {
                    enable = true;
                    nix-direnv.enable = true;
                  };

                  starship = {
                    enable = true;
                    settings = {
                      add_newline = false;
                      format = lib.concatStrings [
                        "$directory"
                        "$nix_shell"
                        "$character"
                      ];
                      line_break = {
                        disabled = true;
                      };
                      nix_shell = {
                        format = "via [(\($name\))](bold blue) ";
                      };
                    };
                  };

                  nushell = {
                    enable = true;
                    shellAliases = {
                      su = "sudo nixos-rebuild switch";
                    };
                    environmentVariables = {
                      VISUAL = "bat";
                      BROWSER = "firefox";
                      TERM = "xterm-256color";
                      _JAVA_AWT_WM_NONREPARENTING = "1";
                    };
                    configFile.text = ''
                      $env.config = {
                        show_banner: false,
                      }
                    '';
                  };

                  firefox = {
                    enable = true;
                    profiles.default = {
                      bookmarks = [
                        {
                          name = "google";
                          tags = ["google"];
                          keyword = "google";
                          url = "https://google.com";
                        }
                      ];
                    };
                  };

                  git = {
                    enable = true;
                    delta.enable = true;
                    extraConfig = {
                      "init" = {
                        defaultBranch = "master";
                      };
                      "credential" = {
                        helper = "store";
                      };
                      "pull" = {
                        rebase = false;
                      };
                      "core" = {
                        editor = "nano";
                      };
                      "user" = {
                        name = "Knarkzel";
                        email = "knarkzel@gmail.com";
                      };
                      "push" = {
                        default = "simple";
                        autoSetupRemote = true;
                      };
                    };
                  };

                  alacritty = {
                    enable = true;
                    settings = {
                      font = {
                        size = 22.5;
                      };
                      key_bindings = [
                        {
                          key = "C";
                          mods = "Alt";
                          action = "Copy";
                        }
                        {
                          key = "V";
                          mods = "Alt";
                          action = "Paste";
                        }
                      ];
                      colors = {
                        primary = {
                          background = "0xf7f3ee";
                          foreground = "0x586e75";
                        };
                        normal = {
                          black = "0x073642";
                          red = "0xdc322f";
                          green = "0x859900";
                          yellow = "0xb58900";
                          blue = "0x268bd2";
                          magenta = "0xd33682";
                          cyan = "0x2aa198";
                          white = "0xeee8d5";
                        };
                        bright = {
                          black = "0x002b36";
                          red = "0xcb4b16";
                          green = "0x586e75";
                          yellow = "0x657b83";
                          blue = "0x839496";
                          magenta = "0x6c71c4";
                          cyan = "0x93a1a1";
                          white = "0xfdf6e3";
                        };
                      };
                    };
                  };
                };

                # XSession
                xsession = {
                  enable = true;
                  initExtra = ''
                    xset -dpms
                    xset s off
                    xbanish &
                    xset r rate 200 50
                    xrandr --output DP-0 --right-of DP-2
                    hsetroot -solid "#f7f3ee"
                  '';
                };

                # Packages for home
                home = {
                  stateVersion = "23.11";
                  packages = with pkgs; [
                    # window manager
                    dmenu
                    xbanish
                    hsetroot

                    # rust
                    (rust-bin.nightly.latest.default.override {
                      extensions = ["rust-src"];
                      targets = ["wasm32-wasi" "wasm32-unknown-unknown"];
                    })
                    mold
                    cargo-watch
                    rust-analyzer
                    cargo-nextest
                    cargo-expand
                    sccache

                    # zig
                    zig
                    zls

                    # typescript
                    bun
                    nodejs
                    nodePackages.npm
                    nodePackages.typescript
                    nodePackages.svelte-language-server
                    nodePackages.typescript-language-server

                    # video
                    mpv
                    xclip
                    yt-dlp

                    # python
                    python310

                    # latex
                    texlive.combined.scheme-full

                    # graphics
                    gimp

                    # other
                    xxd
                    ncdu
                    scrot
                    morph
                    ffmpeg
                    bottom
                    brave
                    gnumake
                    lxrandr
                    bintools
                    imagemagick
                    libreoffice
                    stalonetray
                    audacity
                    entr
                    gdb
                    obs-studio
                    kdenlive
                    vlc
                    sqlite
                    discord
                    vscode
                    sxiv
                    stripe-cli
                    networkmanagerapplet
                    zathura
                    just
                    typst
                  ];
                };
              };
            };
          }
        )
      ];
    };
  };
}
