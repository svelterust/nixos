{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix # Include the results of the hardware scan.
  ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sdb";
  boot.loader.grub.useOSProber = true;

  # Enable networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.utf8";

  # Configure console keymap
  console.keyMap = "colemak";

  # Configure X11
  services.xserver = {
    enable = true;
    windowManager.dwm.enable = true;
    libinput.enable = true;
    layout = "no";
    xkbVariant = "colemak";
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "oddharald";
    };
  };

  # Location for redshift
  location.latitude = 58.0;
  location.longitude = 9.0;
  
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
  };

  # Overlays
  nixpkgs.overlays = [
    # Emacs
    (import (builtins.fetchGit {
      url = "https://github.com/nix-community/emacs-overlay.git";
      ref = "master";
      rev = "a04bc2fc2b6bc9c1ba738cf8de3d33768d298c7c";
    }))

    # dwm
    (final: prev: {
      dwm = prev.dwm.overrideAttrs (drv: {
        src = prev.fetchFromGitHub {
          owner = "knarkzel";
          repo = "dwm";
          rev = "06816fcb2059a007e65f0d16caec519763ab360e";
          sha256 = "Bghri5KmjFRHJKJv4Bi4K304C9d2otUaweVK/j/VJdA=";
        };
      });
    })
  ];
  
  # Define a user account.
  users.users.oddharald = {
    isNormalUser = true;
    description = "Odd-Harald";
    extraGroups = [ "networkmanager" "wheel" ];

    packages = with pkgs; [
      # window manager
      dmenu
      xcape
      dunst
      xbanish
      wmname
      redshift
      hsetroot

      # emacs
      ((emacsPackagesFor emacsNativeComp).emacsWithPackages (epkgs: [
        epkgs.vterm
      ]))
      
      # other
      git
      firefox
      starship
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Emacs with native compilation
  services.emacs.package = pkgs.emacsNativeComp;
  
  # System packages
  environment.systemPackages = with pkgs; [ ];

  system.stateVersion = "22.05";
}
