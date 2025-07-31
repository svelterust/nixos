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

  outputs =
    {
      nixpkgs,
      rust-overlay,
      home-manager,
      firefox-addons,
      raise,
      hyprsome,
      ...
    }@inputs:
    {
      # System
      nixosConfigurations."odd" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (
            {
              pkgs,
              lib,
              ...
            }:
            let
              hosts = pkgs.fetchurl {
                url = "https://raw.githubusercontent.com/StevenBlack/hosts/88ca3222616ca7a0802d6e071ee320ad9e7e7d6b/alternates/fakenews-gambling-porn-only/hosts";
                sha256 = "sha256-9ylM56W3q699xi9TNPGHHxtBwDPCtb4D0YcWv4I76sg=";
              };
              blockList = ''
                0.0.0.0 youtube.com
                0.0.0.0 www.youtube.com
                0.0.0.0 x.com
                0.0.0.0 www.x.com
                0.0.0.0 facebook.com
                0.0.0.0 www.facebook.com
                0.0.0.0 quora.com
                0.0.0.0 www.quora.com
                0.0.0.0 instagram.com
                0.0.0.0 www.instagram.com
                0.0.0.0 tiktok.com
                0.0.0.0 www.tiktok.com
                0.0.0.0 instagram.com
                0.0.0.0 www.instagram.com
              '';
              zed-fhs = pkgs.buildFHSEnv {
                name = "zed-fhs";
                runScript = "zeditor";
                targetPkgs = pkgs: [ pkgs.zed-editor ];
              };
              thinkpad = {
                layout = "us";
                videoDrivers = [
                  "i915"
                  "intel"
                ];
                hardware = ./hardware/thinkpad.nix;
                frameRate = 60;
                bootLoader = {
                  systemd-boot.enable = true;
                  efi.canTouchEfiVariables = true;
                };
              };
              settings = thinkpad;
            in
            {
              # System config
              system.stateVersion = "25.11";

              # Set your time zone.
              time.timeZone = "Africa/Cairo";

              # Configure console keymap
              console.keyMap = "colemak";

              # Imports
              imports = [
                settings.hardware
                "${home-manager}/nixos"
              ];

              # Make it easier to run downloadable binaries
              programs = {
                nix-ld = {
                  enable = true;
                  libraries = with pkgs; [
                    stdenv.cc.cc.lib
                    zlib
                  ];
                };
              };

              # Distrobox
              virtualisation.podman = {
                enable = true;
                dockerCompat = true;
              };

              # Email
              programs.thunderbird = {
                enable = true;
              };

              # Syncing
              services.syncthing = {
                enable = true;
                openDefaultPorts = true;
                user = "odd";
                dataDir = "/home/odd";
                configDir = "/home/odd/.config/syncthing";
                extraFlags = [ "--no-default-folder" ];
              };

              # Fingerprint
              services.fprintd = {
                enable = true;
                tod.enable = true;
                tod.driver = pkgs.libfprint-2-tod1-goodix-550a;
              };

              # Create temporary directory for binaries
              services = {
                envfs = {
                  enable = true;
                };
              };

              # Zram
              zramSwap = {
                enable = true;
                memoryPercent = 50;
                algorithm = "zstd";
              };

              # Configuration
              nixpkgs = {
                config.allowUnfree = true;
              };

              # Game mode
              programs.gamemode.enable = true;

              # Programs
              programs = {
                adb.enable = true;
                ssh.askPassword = "";
              };

              # Bootloader
              boot = {
                loader = settings.bootLoader;
                kernelPackages = pkgs.linuxPackages_zen;
              };

              # Enable sound
              security.rtkit.enable = true;

              # Swaylock hack fix
              security.pam.services.swaylock = { };

              # Enable networking
              networking = {
                hostName = "odd";
                firewall = {
                  enable = true;
                  connectionTrackingModules = [
                    "ftp"
                    "irc"
                    "sane"
                  ];
                  autoLoadConntrackHelpers = false; # Reduces overhead
                };
                networkmanager.enable = true;
                extraHosts = (builtins.readFile hosts) + blockList;
                nameservers = [
                  "1.1.1.1"
                  "8.8.8.8"
                ];
              };
              services.irqbalance.enable = true;

              # Enable OpenGL and bluetooth
              hardware = {
                bluetooth.enable = true;
                graphics = {
                  enable = true;
                  extraPackages = with pkgs; [
                    vaapiIntel
                    libvdpau-va-gl
                    intel-media-driver
                  ];
                };
              };

              # PostgreSQL
              services.postgresql = {
                enable = true;
                enableTCPIP = true;
                extensions = ps: with ps; [ pgvector ];
                authentication = pkgs.lib.mkOverride 10 ''
                  #type database DBuser origin-address auth-method
                  local all      all     trust
                  # ipv4
                  host  all      all     127.0.0.1/32   trust
                  # ipv6
                  host  all      all     ::1/128        trust
                '';
              };

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
                  trusted-users = [
                    "root"
                    "odd"
                  ];
                  experimental-features = [
                    "nix-command"
                    "flakes"
                  ];
                  auto-optimise-store = true;
                  keep-derivations = false;
                  keep-outputs = false;
                };
                registry.nixpkgs.flake = inputs.nixpkgs;
              };

              # Capslock as Control + Escape everywhere
              services.interception-tools =
                let
                  dfkConfig = pkgs.writeText "dual-function-keys.yaml" ''
                    MAPPINGS:
                      - KEY: KEY_CAPSLOCK
                        TAP: KEY_ESC
                        HOLD: KEY_LEFTCTRL
                  '';
                in
                {
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
                geist-font
                noto-fonts-emoji
                jetbrains-mono
              ];

              # Use Fish as default shell
              programs.bash = {
                interactiveShellInit = ''
                  if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
                  then
                    shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
                    exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
                  fi
                '';
              };

              # Manage environment
              environment = {
                binsh = "${pkgs.dash}/bin/dash";
                systemPackages = with pkgs; [
                  gcc
                  stdenv.cc.cc.lib
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
                  distrobox
                  vanilla-dmz # cursor theme
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
                  shell = pkgs.bash;
                  description = "Odd-Harald";
                  extraGroups = [
                    "networkmanager"
                    "wheel"
                    "docker"
                    "dialout"
                    "video"
                    "adbusers"
                    "input"
                    "render"
                    "kvm"
                  ];
                  hashedPassword = "$6$/GQatAaT7h0hvkZu$XQIrOflYDVukuW1WW7AWX7v9LhFHAk8YhkRvrSkBKYw5P3jazaEV0.u34t9CK/UMBF6eWohc/H97BlXdEYXZX0";
                };
                groups.render = { };
              };

              services.udev.extraRules = ''
                # DRM devices
                SUBSYSTEM=="drm", GROUP="video", MODE="0664"
                KERNEL=="renderD*", GROUP="render", MODE="0666"

                # Allow access to card devices
                KERNEL=="card*", SUBSYSTEM=="drm", GROUP="video", MODE="0664", TAG+="uaccess"
              '';

              # Manage user account with home manager
              home-manager = {
                backupFileExtension = "hm-backup";
                users.odd =
                  {
                    pkgs,
                    config,
                    ...
                  }:
                  {
                    # Overlays
                    nixpkgs = {
                      config.allowUnfree = true;
                      overlays = [
                        # rust
                        rust-overlay.overlays.default
                      ];
                    };

                    # User dirs and default applications
                    xdg = {
                      userDirs = {
                        enable = true;
                        desktop = "${config.home.homeDirectory}";
                        documents = "${config.home.homeDirectory}";
                        music = "${config.home.homeDirectory}";
                        pictures = "${config.home.homeDirectory}";
                        publicShare = "${config.home.homeDirectory}";
                        templates = "${config.home.homeDirectory}";
                        videos = "${config.home.homeDirectory}";
                        download = "${config.home.homeDirectory}/downloads";
                      };
                      mimeApps = {
                        enable = true;
                        defaultApplications = {
                          "image/png" = [ "sxiv.desktop" ];
                          "image/jpeg" = [ "sxiv.desktop" ];
                          "image/jpg" = [ "sxiv.desktop" ];
                          "image/gif" = [ "sxiv.desktop" ];
                          "image/bmp" = [ "sxiv.desktop" ];
                          "image/tiff" = [ "sxiv.desktop" ];
                          "image/webp" = [ "sxiv.desktop" ];
                          "image/svg+xml" = [ "sxiv.desktop" ];
                          "video/mp4" = [ "mpv.desktop" ];
                          "video/webm" = [ "mpv.desktop" ];
                          "video/avi" = [ "mpv.desktop" ];
                          "video/mkv" = [ "mpv.desktop" ];
                          "video/x-matroska" = [ "mpv.desktop" ];
                          "video/quicktime" = [ "mpv.desktop" ];
                          "video/x-msvideo" = [ "mpv.desktop" ];
                          "video/ogg" = [ "mpv.desktop" ];
                          "video/3gpp" = [ "mpv.desktop" ];
                          "video/x-flv" = [ "mpv.desktop" ];
                          "audio/mpeg" = [ "mpv.desktop" ];
                          "audio/ogg" = [ "mpv.desktop" ];
                          "audio/wav" = [ "mpv.desktop" ];
                          "audio/flac" = [ "mpv.desktop" ];
                          "audio/aac" = [ "mpv.desktop" ];
                          "audio/mp4" = [ "mpv.desktop" ];
                          "text/html" = [ "firefox.desktop" ];
                          "application/pdf" = [ "firefox.desktop" ];
                          "x-scheme-handler/http" = [ "firefox.desktop" ];
                          "x-scheme-handler/https" = [ "firefox.desktop" ];
                          "x-scheme-handler/chrome" = [ "firefox.desktop" ];
                          "application/x-extension-htm" = [ "firefox.desktop" ];
                          "application/x-extension-html" = [ "firefox.desktop" ];
                          "application/x-extension-shtml" = [ "firefox.desktop" ];
                          "application/xhtml+xml" = [ "firefox.desktop" ];
                          "application/x-extension-xhtml" = [ "firefox.desktop" ];
                          "application/x-extension-xht" = [ "firefox.desktop" ];
                          "x-scheme-handler/mailto" = [ "userapp-Thunderbird-ZVTW92.desktop" ];
                          "message/rfc822" = [ "userapp-Thunderbird-ZVTW92.desktop" ];
                          "x-scheme-handler/mid" = [ "userapp-Thunderbird-ZVTW92.desktop" ];
                        };
                      };
                    };

                    # Fonts
                    fonts = {
                      fontconfig.enable = true;
                    };

                    # Custom dotfiles
                    home.file = {
                      ".config/hypr" = {
                        source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/hyprland";
                        recursive = true;
                        force = true;
                      };

                      ".config/zed" = {
                        source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/zed";
                        recursive = true;
                        force = true;
                      };

                      ".config/ghostty" = {
                        source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/ghostty";
                        recursive = true;
                        force = true;
                      };

                      ".config/fuzzel" = {
                        source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/fuzzel";
                        recursive = true;
                        force = true;
                      };

                      ".config/swaync" = {
                        source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/swaync";
                        recursive = true;
                        force = true;
                      };

                      ".cargo/config.toml" = {
                        source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/cargo/config.toml";
                        force = true;
                      };

                      ".claude/CLAUDE.md" = {
                        source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/claude/CLAUDE.md";
                        force = true;
                      };
                    };

                    # Services
                    services = {
                      gammastep = {
                        enable = true;
                        latitude = 30.07;
                        longitude = 31.69;
                        temperature = {
                          day = 6500;
                          night = 2000;
                        };
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
                        extraOptions = [ "--group-directories-first" ];
                      };

                      direnv = {
                        enable = true;
                        nix-direnv.enable = true;
                        silent = true;
                      };

                      starship = {
                        enable = true;
                        settings = {
                          add_newline = false;
                          format = lib.concatStrings [
                            "$directory"
                            "$git_branch"
                            "$git_status"
                            "$nix_shell"
                            "$character"
                          ];
                          line_break = {
                            disabled = true;
                          };
                          nix_shell = {
                            format = "via [nix](bold blue) ";
                          };
                        };
                      };

                      fish = {
                        enable = true;
                        shellAliases = {
                          zed = "zeditor";
                          cat = "bat --style=plain --no-pager";
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
                          ls = "eza --sort ext";
                        };
                        shellInit = ''
                          set -x BROWSER firefox
                          set -x TERM xterm-256color
                          set -x NIXPKGS_ALLOW_UNFREE 1
                          set -x ERL_AFLAGS "-kernel shell_history enabled"
                          set -x PLUG_EDITOR "zed://file/__FILE__:__LINE__"
                          set -x LAUNCH_EDITOR "/home/odd/.config/zed/zed.sh"
                          set -x VISUAL "/home/odd/.config/zed/zed.sh"
                          set -x EDITOR "/home/odd/.config/zed/zed.sh"
                          fish_add_path /home/odd/.bun/bin
                        '';
                        interactiveShellInit = ''
                          set fish_greeting
                        '';
                        plugins = [
                          {
                            name = "autopair";
                            src = pkgs.fishPlugins.autopair.src;
                          }
                        ];
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
                          extensions.packages = with firefox-addons.packages."x86_64-linux"; [
                            ublock-origin
                            i-dont-care-about-cookies
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
                            editor = "micro";
                          };
                          "user" = {
                            name = "SvelteRust";
                            email = "oddharald@myhren.ai";
                          };
                          "push" = {
                            default = "simple";
                            autoSetupRemote = true;
                          };
                        };
                      };
                    };

                    # Packages for home
                    home = {
                      stateVersion = "25.11";
                      packages = with pkgs; [
                        # Audio
                        mpv

                        # Build Tools
                        gcc
                        gnumake
                        just
                        mold
                        sccache

                        # Browsers & Web
                        chromium
                        chromedriver

                        # Development Tools
                        gitui
                        ghostty
                        cargo-nextest
                        cargo-watch
                        elixir
                        gh
                        inotify-tools
                        lexical
                        nodePackages.svelte-language-server
                        nodePackages.typescript
                        nodePackages.typescript-language-server
                        nodePackages.vscode-json-languageserver
                        nodejs_22
                        pgcli
                        protobuf
                        python3
                        ruff
                        (rust-bin.nightly.latest.default.override {
                          extensions = [
                            "rust-src"
                            "rust-analyzer"
                          ];
                        })
                        sqlite
                        uv

                        # Editors
                        micro
                        zed-editor
                        zed-fhs

                        # Crypto
                        exodus

                        # File & Directory
                        eza
                        fd
                        ncdu

                        # GUI Applications
                        gimp
                        libreoffice

                        # Image & Graphics
                        ghostscript
                        imagemagick
                        sxiv

                        # Claude Code
                        claude-code

                        # Supabase
                        supabase-cli

                        # Monitoring & Profiling
                        bottom
                        powertop

                        # Networking & Connectivity
                        flyctl
                        ngrok
                        stripe-cli

                        # Nix
                        alejandra

                        # Utilities
                        ffmpeg
                        jq
                        xclip
                        yt-dlp
                        bun

                        # Zig
                        zig
                        zls

                        # Slint
                        slint-lsp

                        # Nix
                        nil
                        nixd

                        # Mattermost
                        mattermost-desktop

                        # Wayland
                        brightnessctl
                        fuzzel
                        grim
                        hyprpicker
                        hyprsome.packages.x86_64-linux.default
                        libnotify
                        qt6.qtwayland
                        raise.defaultPackage.x86_64-linux
                        slurp
                        swayidle
                        swaylock
                        swaynotificationcenter
                        wl-clipboard
                        xdg-utils
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
