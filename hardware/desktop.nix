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
  boot.extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
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
    nvidiaSettings = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    forceFullCompositionPipeline = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  swapDevices = [];
  powerManagement.cpuFreqGovernor = "balanced";
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Powersaving options
  boot.kernelParams = [
    "nmi_watchdog=0"
  ];
}
