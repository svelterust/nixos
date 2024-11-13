{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
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
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    home-manager,
    firefox-addons,
    raise,
    hyprsome,
    zig-overlay,
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
              url = "https://raw.githubusercontent.com/StevenBlack/hosts/88ca3222616ca7a0802d6e071ee320ad9e7e7d6b/alternates/fakenews-gambling-porn-only/hosts";
              sha256 = "sha256-9ylM56W3q699xi9TNPGHHxtBwDPCtb4D0YcWv4I76sg=";
            };
            blockList = ''
              0.0.0.0 quora.com
              0.0.0.0 www.quora.com
              0.0.0.0 store.steampowered.com
              0.0.0.0 steamcommunity.com
              0.0.0.0 api.steampowered.com
              0.0.0.0 cdn.steampowered.com
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
            system.stateVersion = "24.11";

            # Set your time zone.
            time.timeZone = "Europe/Oslo";

            # Select internationalisation properties.
            i18n.defaultLocale = "en_US.utf8";

            # Configure console keymap
            console.keyMap = "colemak";

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
              adb.enable = true;
              ssh.askPassword = "";
            };

            # Bootloader
            boot = {
              loader = settings.bootLoader;
              supportedFilesystems = ["ntfs"];
            };

            # Enable sound
            security.rtkit.enable = true;

            # Swaylock hack fix
            security.pam.services.swaylock = {};

            # Enable networking
            networking = {
              hostName = "odd";
              firewall.enable = true;
              networkmanager.enable = true;
              extraHosts = (builtins.readFile hosts) + blockList;
              nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
            };

            # Enable OpenGL and bluetooth
            hardware = {
              bluetooth.enable = true;
              opengl = {
                enable = true;
                extraPackages = with pkgs; [
                  vaapiIntel
                  vaapiVdpau
                  libvdpau-va-gl
                  intel-media-driver
                ];
              };
            };

	    # Docker compose
            virtualisation.docker.enable = true;

            # Hyprland
            programs.hyprland = {
              enable = true;
              xwayland = {
                enable = true;
              };
            };

            # XDG Portals
            xdg = {
              autostart.enable = true;
              portal = {
                enable = true;
                wlr.enable = true;
                extraPortals = with pkgs; [
                  xdg-desktop-portal
                  xdg-desktop-portal-hyprland
                ];
              };
            };

            # Services
            services = {
              pcscd.enable = true;
              dbus = {
                enable = true;
                implementation = "broker";
              };
              usbmuxd.enable = true;
              blueman.enable = true;
              gnome.gnome-keyring.enable = true;
              libinput = {
                enable = true;
                mouse.accelSpeed = "0";
              };
              displayManager = {
                autoLogin.enable = true;
                autoLogin.user = "odd";
              };
              xserver = {
                enable = true;
                videoDrivers = settings.videoDrivers;
                xkb = {
                  variant = "colemak";
                  layout = settings.layout;
                };
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
                keep-derivations = false;
                keep-outputs = false;
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
              geist-font
              noto-fonts-emoji
              inter
              ibm-plex
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
              enableSSHSupport = true;
            };

            # Define user account.
            users = {
              users.odd = {
                isNormalUser = true;
                description = "Odd-Harald";
                extraGroups = ["networkmanager" "wheel" "docker" "dialout" "video" "adbusers" "kvm"];
                hashedPassword = "$6$/GQatAaT7h0hvkZu$XQIrOflYDVukuW1WW7AWX7v9LhFHAk8YhkRvrSkBKYw5P3jazaEV0.u34t9CK/UMBF6eWohc/H97BlXdEYXZX0";
              };
            };

            # Manage user account with home manager
            home-manager = {
              backupFileExtension = "hm-backup";
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

                # User dirs and default applications
                xdg = {
                  userDirs = {
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
                  mimeApps = {
                    enable = true;
                    defaultApplications = {
                      "image/png" = ["sxiv.desktop"];
                      "image/jpeg" = ["sxiv.desktop"];
                      "image/gif" = ["sxiv.desktop"];
                      "video/mp4" = ["mpv.desktop"];
                      "video/webm" = ["mpv.desktop"];
                      "application/pdf" = ["firefox.desktop"];
                    };
                  };
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

                  ".config/hypr" = {
                    source = ./dotfiles/hyprland;
                    recursive = true;
                  };

                  ".config/alacritty/theme.toml" = {
                    source = ./dotfiles/alacritty/catppuccin-latte.toml;
                  };

                  ".config/Code/User/settings.json" = {
                    source = ./dotfiles/vscode/settings.json;
                  };

                  ".mozilla/firefox/default/chrome" = {
                    source = ./dotfiles/firefox/chrome;
                  };

                  ".ssh/config" = {
                    source = ./dotfiles/ssh/config;
                  };

        		  ".config/zed/settings.json" = {
                    source = ./dotfiles/zed/settings.json;
        		  };

                  ".config/zed/keymap.json" = {
                    source = ./dotfiles/zed/keymap.json;
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
                  gammastep = {
                    enable = true;
                    latitude = 58.4;
                    longitude = 8.6;
                    temperature = {
                      day = 5500;
                      night = 1750;
                    };
                  };
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

                  obs-studio = {
                    enable = true;
                    plugins = [ pkgs.obs-studio-plugins.wlrobs ];
                  };

                  eza = {
                    enable = true;
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
                      zed = "zeditor";
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
                      zw = "zig build --watch";
                      ls = "eza --git-ignore --sort ext";
                    };
                    sessionVariables = {
                      VISUAL = "zeditor";
                      EDITOR = "zeditor";
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
                        "security.tls.enable_0rtt_data" = false;
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
                      keyboard.bindings = [
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
                      general.import = [
                        "~/.config/alacritty/theme.toml"
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
                  gtk3.extraConfig = {
                    gtk-recent-files-enabled = 0;
                  };
                  gtk4.extraConfig = {
                    gtk-recent-files-enabled = 0;
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
                    xdg-utils
                    libnotify
                    hyprpicker
                    wl-clipboard
                    qt6.qtwayland
                    brightnessctl
                    swayidle
                    swaylock
                    raise.defaultPackage.x86_64-linux
                    hyprsome.packages.x86_64-linux.default

                    # nix
                    nil

                    # php
                    php
                    nodePackages.intelephense

                    # video
                    mpv
                    xclip

                    # python
                    ruff
                    pyright
                    (python3.withPackages (ps: with ps; [epc orjson sexpdata six paramiko rapidfuzz setuptools django]))

                    # typescript
                    nodejs_22
                    yarn
                    tailwindcss
                    nodePackages.typescript
                    nodePackages.svelte-language-server
                    nodePackages.typescript-language-server
                    tailwindcss-language-server
                    nodePackages.vscode-json-languageserver

                    # rust
                    (rust-bin.nightly.latest.default.override {
                      extensions = ["rust-src" "rust-analyzer" "rustc-codegen-cranelift"];
                      targets = ["wasm32-wasi" "wasm32-unknown-unknown"];
                    })
                    mold
                    cargo-watch
                    cargo-nextest
                    sccache

                    # terminal applications
                    gdb
                    xxd
                    ncdu
                    just
                    ffmpeg
                    bottom
                    gnumake
                    imagemagick
                    jq
                    sxiv

                    # gui
                    gimp
                    libreoffice
                    deploy-rs

					# minecraft
					prismlauncher

                    # bun stack
                    bun

                    # http
                    ngrok
                    bruno
                    stripe-cli

                    # other
                    powertop
                    graphviz
                    fd
                    yt-dlp
                    typst

                    # docker
                    docker-compose

	                # git
                    gitui

                    # fly
                    flyctl

                    # zed
                    zed-editor
                    # zed-editor.packages.x86_64-linux.default

                    # lf
                    lf

                    # audio
                    audacious

                    # ruby
                    sqlite
                    gcc

                    # micro
                    micro

                    # nix
                    nixd

					# elixir
					elixir
					inotify-tools

					# davinci
					# davinci-resolve

                    # zig
                    zig-overlay.packages.${system}.master

                    # turso
                    turso-cli
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
