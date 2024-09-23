{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "vmd" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = ["nvidia"];
  boot.kernelModules = ["kvm-intel"];
  # boot.extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
  boot.extraModprobeConfig = ''
    options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x3; PowerMizerDefault=0x3; PowerMizerDefaultAC=0x3"
    # Necessary for the one below it
    options nvidia NVreg_RegistryDwords="OverrideMaxPerf=0x1"

    # Fixes broken sleep on wayland
    # https://github.com/hyprwm/Hyprland/issues/1728#issuecomment-1571852169
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/910228bd-977b-4b7a-94a8-5a2b6bbc77ef";
    fsType = "ext4";
    options = ["defaults" "noatime"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6DB5-F388";
    fsType = "vfat";
    options = ["defaults" "noatime"];
   };

  fileSystems."/home/odd/harddrive" = {
    device = "/dev/disk/by-uuid/30246B65246B2CD2";
    fsType = "ntfs";
    options = ["defaults" "noatime" "rw" "uid=1000" "gid=100"];
  };

  hardware.nvidia = {
    open = false;
    nvidiaSettings = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    forceFullCompositionPipeline = true;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "555.58";
        sha256_64bit = "sha256-bXvcXkg2kQZuCNKRZM5QoTaTjF4l2TtrsKUvyicj5ew=";
        sha256_aarch64 = "sha256-7XswQwW1iFP4ji5mbRQ6PVEhD4SGWpjUJe1o8zoXYRE=";
        openSha256 = "sha256-hEAmFISMuXm8tbsrB+WiUcEFuSGRNZ37aKWvf0WJ2/c=";
        settingsSha256 = "sha256-vWnrXlBCb3K5uVkDFmJDVq51wrCoqgPF03lSjZOuU8M=";
        persistencedSha256 = "sha256-lyYxDuGDTMdGxX3CaiWUh1IQuQlkI2hPEs5LI20vEVw=";
    };
    # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    #   version = "535.154.05";
    #   sha256_64bit = "sha256-fpUGXKprgt6SYRDxSCemGXLrEsIA6GOinp+0eGbqqJg=";
    #   sha256_aarch64 = "sha256-G0/GiObf/BZMkzzET8HQjdIcvCSqB1uhsinro2HLK9k=";
    #   openSha256 = "sha256-wvRdHguGLxS0mR06P5Qi++pDJBCF8pJ8hr4T8O6TJIo=";
    #   settingsSha256 = "sha256-9wqoDEWY4I7weWW05F4igj1Gj9wjHsREFMztfEmqm10=";
    #   persistencedSha256 = "sha256-d0Q3Lk80JqkS1B54Mahu2yY/WocOqFFbZVBh+ToGhaE=";
    # };
  };

  swapDevices = [];
  powerManagement.cpuFreqGovernor = "performance";
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Powersaving options
  boot.kernelParams = [
    "nmi_watchdog=0"
  ];
}
