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

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "usbhid" "uas" "sd_mod"];
  boot.initrd.kernelModules = ["nvidia"];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [config.boot.kernelPackages.nvidia_x11];
  boot.extraModprobeConfig = ''
    options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x3; PowerMizerDefault=0x3; PowerMizerDefaultAC=0x3"
  '';

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/caf288af-82c8-4c26-802d-df773ec084ca";
    fsType = "ext4";
  };

  fileSystems."/home/odd/source/storage" = {
    device = "/dev/disk/by-uuid/86e55879-4b55-441b-9221-8fc909f4d772";
    fsType = "ext4";
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
