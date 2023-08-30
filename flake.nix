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
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    raise = {
      url = "github:knarkzel/raise";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    emacs-overlay,
    home-manager,
    firefox-addons,
    raise,
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

            # Imports
            imports = [
              settings.hardware
              "${home-manager}/nixos"
            ];

            # Zram
            zramSwap = {
              enable = true;
              memoryPercent = 50;
            };
            
            nixpkgs = {
              config.allowUnfree = true;
              overlays = [
                # latest emacs
                emacs-overlay.overlays.default
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

            # Hyprland
            programs.hyprland = {
              enable = true;
              xwayland = {
                enable = true;
              };
              enableNvidiaPatches = true;
            };

            # XDG Portals
            xdg = {
              autostart.enable = true;
              portal = {
                enable = true;
                extraPortals = with pkgs; [
                  xdg-desktop-portal
                  xdg-desktop-portal-gtk
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
                package = with pkgs; ((emacsPackagesFor emacs-pgtk).emacsWithPackages (epkgs: [epkgs.vterm]));
              };

              picom = {
                enable = true;
                shadow = true;
                shadowOpacity = 0.25;
              };
              
              pipewire = {
                enable = true;
                alsa.enable = true;
                alsa.support32Bit = true;
                pulse.enable = true;
                jack.enable = true;
                wireplumber.enable = true;
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
                ripgrep
                alejandra
                e2fsprogs
                dosfstools
                libimobiledevice
                interception-tools
              ];
              etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;
            };

            # Define user account.
            users = {
              users.odd = {
                isNormalUser = true;
                description = "Odd-Harald";
                extraGroups = ["networkmanager" "wheel" "docker" "dialout"];
              };
            };

            # Steam
            programs.steam.enable = true;
            
            # Manage user account with home manager
            home-manager = {
              backupFileExtension = "backup";
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
                  
                  ".config/hypr" = {
                    source = ./dotfiles/hyprland;
                    recursive = true;
                  };

                  ".config/alacritty/catpuccin-latte.yml" = {
                    source = ./dotfiles/alacritty/catppuccin-latte.yml;
                  };

                  ".config/alacritty/catpuccin-mocha.yml" = {
                    source = ./dotfiles/alacritty/catppuccin-mocha.yml;
                  };

                  ".mozilla/firefox/default/chrome" = {
                    source = ./dotfiles/firefox/chrome;
                  };
                  
                  ".config/tofi/config" = {
                    source = pkgs.writeText "config" ''
                      width = 100%
                      height = 100%
                      border-width = 0
                      outline-width = 0
                      padding-left = 35%
                      padding-top = 40%
                      result-spacing = 5
                      num-results = 5
                      ascii-input = true
                      hint-font = false
                      background-color = #000C
                      selection-color = #1E66F5
                      font = ${pkgs.hack-font}/share/fonts/hack/Hack-Regular.ttf
                    '';
                  };
                };

                # Services
                services = {
                  mako = {
                    enable = true;
                  };

                  wlsunset = {
                    enable = true;
                    latitude = "58.0";
                    longitude = "9.0";
                  };
                };

                # Configure programs
                programs = {
                  bat = {
                    enable = true;
                  };

                  fzf = {
                    enable = true;
                  };

                  exa = {
                    enable = true;
                    enableAliases = true;
                    extraOptions = ["--group-directories-first"];
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

                  bash = {
                    enable = true;
                    shellAliases = {
                      cat = "bat";
                      tmp = "cd $(mktemp -d); clear";
                      su = "sudo nixos-rebuild switch";
                      cr = "cargo run";
                      cb = "cargo check";
                      ct = "cargo nextest run";
                      cdo = "cargo doc --open";
                      zb = "zig build";
                      zr = "zig build run";
                      zt = "zig build test";
                      edit = "emacseditor -nw";
                    };
                    sessionVariables = {
                      VISUAL = "bat";
                      BROWSER = "firefox";
                    };
                    bashrcExtra = lib.readFile ./dotfiles/bash/.bashrc;
                  };

                  firefox = {
                    enable = true;
                    profiles.default = {
                      settings = {
                        "layout.frame_rate" = 144;
                        "extensions.autoDisableScopes" = 0;
                        "browser.sessionstore.restore_on_demand" = false;
                        "browser.sessionstore.resume_from_crash" = false;
                        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
                      };
                      extensions = with firefox-addons.packages."x86_64-linux"; [
                        sponsorblock
                        ublock-origin
                        i-dont-care-about-cookies
                        youtube-shorts-block
                        auto-tab-discard
                        automatic-dark
                        df-youtube
                        disconnect
                        darkreader
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
                      import = [
                        "~/.config/alacritty/theme.yml"
                      ];
                    };
                  };
                };

                # GTK theme
                gtk = {
                  enable = true;
                  theme = {
                    name = "Catppuccin-Latte";
                    package = pkgs.catppuccin-gtk.override {
                      variant = "latte";
                    };
                  };
                };
                
                # Packages for home
                home = {
                  stateVersion = "23.11";
                  packages = with pkgs; [
                    # wayland
                    tofi
                    grim
                    slurp
                    libnotify
                    hyprpicker
                    wl-clipboard
                    qt6.qtwayland
                    raise.defaultPackage.x86_64-linux
                    
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
                    (python311.withPackages(ps: with ps; [ epc orjson sexpdata six paramiko rapidfuzz ]))
                    
                    # latex
                    texlive.combined.scheme-full

                    # graphics
                    gimp

                    # other
                    xxd
                    ncdu
                    morph
                    ffmpeg
                    bottom
                    gnumake
                    bintools
                    imagemagick
                    libreoffice
                    audacity
                    stripe-cli
                    obs-studio
                    kdenlive
                    entr
                    gdb
                    sqlite
                    discord
                    vscode
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
