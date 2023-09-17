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
  '';

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/940144e0-6512-4d5f-9700-a76d2fd9fc25";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/01FD-E99A";
      fsType = "vfat";
    };

  hardware.nvidia = {
    nvidiaSettings = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    forceFullCompositionPipeline = true;
  };

  swapDevices = [];
  powerManagement.cpuFreqGovernor = "performance";
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
