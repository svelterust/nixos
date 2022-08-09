{
  config,
  pkgs,
  lib,
  ...
}: let
  hosts = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/StevenBlack/hosts/bc271a3f6a55c8da8a0b6fd46ad34647861019c0/alternates/fakenews-gambling-porn-social/hosts";
    sha256 = "x8Deah7rEfPMUhXGJX8DB7EcA9Mo52JebzX6XaPJtNY=";
  };
in {
  imports = [
    ./hardware-configuration.nix
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
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
  };

  services.xserver.videoDrivers = ["nvidia"];
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
  powerManagement.cpuFreqGovernor = "ondemand";

  # Configure console keymap
  console.keyMap = "colemak";

  # Docker
  virtualisation.docker.enable = true;

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
    libimobiledevice
    interception-tools
    fd
    git
    ripgrep
    zip
    unzip
    file
    psmisc
    tldr
    clang
    p7zip
    dig
    e2fsprogs
    dosfstools
    direnv
    nix-direnv
  ];

  environment.pathsToLink = [
    "/share/nix-direnv"
  ];

  # Define user account.
  users.users.odd = {
    isNormalUser = true;
    description = "Odd-Harald";
    extraGroups = ["networkmanager" "wheel" "docker"];

    packages = with pkgs; [
      # window manager
      dmenu
      dunst
      xbanish
      hsetroot

      # emacs
      ((emacsPackagesFor emacsNativeComp).emacsWithPackages (epkgs: [epkgs.vterm]))

      # rust
      (rust-bin.stable.latest.default.override {
        extensions = ["rust-src"];
        targets = ["wasm32-unknown-unknown"];
      })
      rust-analyzer
      mold
      cargo-watch

      # zig
      zig
      zls

      # haskell
      ghc
      cabal-install
      haskell-language-server

      # typescript
      nodePackages.typescript
      nodePackages.typescript-language-server

      # nix
      niv
      rnix-lsp

      # latex
      texlab
      texlive.combined.scheme-full

      # python
      python310
      python-language-server

      # database
      sqlite

      # common lisp
      sbcl

      # scala
      scala
      metals

      # prolog
      swiProlog
      
      # work
      zoom-us
      slack
      docker-compose

      # other
      ncdu
      zola
      starship
      alacritty
      firefox
      ffmpeg
      mpv
      scrot
      mupdf
      lxrandr
      dolphin-emu-beta
      morph
      imagemagick
      exif
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
