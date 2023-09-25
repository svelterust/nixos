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
    hyprsome = {
      url = "github:sopa0/hyprsome";
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
    hyprsome,
    ...
  } @ inputs: {
    # Default formatter
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    # System
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
            extra = ''
              0.0.0.0 reddit.com
              0.0.0.0 www.reddit.com
              0.0.0.0 twitter.com
              0.0.0.0 www.twitter.com
            '';
            desktop = {
              layout = "us";
              videoDrivers = ["nvidia"];
              hardware = ./hardware/desktop.nix;
              frameRate = 144;
              terminalSize = 22.5;
              bootLoader = {
                efi = {
                  canTouchEfiVariables = true;
                  efiSysMountPoint = "/boot";
                };
                grub = {
                  devices = [ "nodev" ];
                  efiSupport = true;
                  enable = true;
                  extraEntries = ''
                    menuentry "Windows" {
                      insmod part_gpt
                      insmod fat
                      insmod search_fs_uuid
                      insmod chain
                      search --fs-uuid --set=root 0A3F-200A
                      chainloader /EFI/Microsoft/Boot/bootmgfw.efi
                    }
                  '';
                };
              };
            };
            thinkpad = {
              layout = "no";
              videoDrivers = [];
              hardware = ./hardware/thinkpad.nix;
              frameRate = 60;
              terminalSize = 14.5;
              bootLoader = {
                grub.enable = true;
                grub.device = "/dev/nvme0n1";
                grub.useOSProber = true;
              };
            };
            hp = {
              layout = "no";
              videoDrivers = [];
              hardware = ./hardware/hp.nix;
              frameRate = 60;
              terminalSize = 14.5;
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

            # Configuration
            nixpkgs = {
              config.allowUnfree = true;
            };

            # Programs
            programs = {
              ssh.askPassword = "";
            };

            # Steam
            programs.steam.enable = true;
            
            # Bootloader
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
              extraHosts = (builtins.readFile hosts) + extra;
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
                wlr.enable = true;
                extraPortals = with pkgs; [
                  xdg-desktop-portal
                  xdg-desktop-portal-gtk
                ];
              };
            };
            
            # Services
            services = {
              pcscd.enable = true;
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
                e2fsprogs
                dosfstools
                libimobiledevice
                interception-tools
              ];
              etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;
            };

            # GPG
            programs.gnupg.agent = {
              enable = true;
              pinentryFlavor = "gtk2";
              enableSSHSupport = true;
            };

            # Define user account.
            users = {
              users.odd = {
                isNormalUser = true;
                description = "Odd-Harald";
                extraGroups = ["networkmanager" "wheel" "docker" "dialout" "video"];
              };
            };

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
                    # latest emacs
                    emacs-overlay.overlays.default
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

                  ".config/alacritty/theme.yml" = {
                    source = ./dotfiles/alacritty/catppuccin-latte.yml;
                  };

                  ".config/Code/User/settings.json" = {
                    source = ./dotfiles/vscode/settings.json;
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
                    padding = "10";
                    font = "monospace 14";
                    extraConfig = ''
                      background-color=#eff1f5
                      text-color=#4c4f69
                      border-color=#1e66f5
                      progress-color=over #ccd0da

                      [urgency=high]
                      border-color=#fe640b
                    '';
                  };
                  swayosd = {
                    enable = true;
                  };
                };

                # Configure programs
                programs = {
                  bat = {
                    enable = true;
                    config = {
                      theme = "ansi";
                    };
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
                    };
                    sessionVariables = {
                      VISUAL = "bat";
                      BROWSER = "firefox";
                      NIXPKGS_ALLOW_UNFREE = "1";
                    };
                    bashrcExtra = lib.readFile ./dotfiles/bash/.bashrc;
                  };

                  firefox = {
                    enable = true;
                    profiles.default = {
                      settings = {
                        "layout.frame_rate" = settings.frameRate;
                        "extensions.autoDisableScopes" = 0;
                        "browser.sessionstore.restore_on_demand" = false;
                        "browser.sessionstore.resume_from_crash" = false;
                        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
                        "network.captive-portal-service.enabled" = false;
                        "browser.selfsupport.url" = "";
                        "pocket.enabled" = false;
                      };
                      extensions = with firefox-addons.packages."x86_64-linux"; [
                        sponsorblock
                        ublock-origin
                        i-dont-care-about-cookies
                        youtube-shorts-block
                        df-youtube
                        disconnect
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
                        size = settings.terminalSize;
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
                    swayosd
                    xdg-utils
                    libnotify
                    hyprpicker
                    wl-clipboard
                    qt6.qtwayland
                    raise.defaultPackage.x86_64-linux
                    hyprsome.packages.x86_64-linux.default
                    
                    # nix
                    nil
                    
                    # video
                    mpv
                    xclip
                    yt-dlp

                    # emacs
                    ((emacsPackagesFor emacs-pgtk).emacsWithPackages (epkgs: [epkgs.vterm]))

                    # zig
                    zig
                    zls

                    # python
                    ruff
                    nodePackages.pyright
                    (python311.withPackages (ps: with ps; [epc orjson sexpdata six paramiko rapidfuzz]))

                    # typescript
                    bun
                    nodejs
                    tailwindcss
                    nodePackages.typescript
                    nodePackages.svelte-language-server
                    nodePackages.typescript-language-server

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

                    # typst
                    typst
                    typst-lsp

                    # terminal applications
                    gdb
                    xxd
                    ncdu
                    just
                    morph
                    ffmpeg
                    bottom
                    gnumake
                    bintools
                    imagemagick

                    # gui
                    gimp
                    prismlauncher
                    libreoffice
                    audacity
                    obs-studio
                    kdenlive
                    discord
                    vscode
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
