{ config, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    initrd = {
      availableKernelModules =
        [ "nvme" "xhci_pci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ ];
      luks.devices."luks-64e34b3e-c037-48ea-b11a-64ebbe3fb11c".device =
        "/dev/disk/by-uuid/64e34b3e-c037-48ea-b11a-64ebbe3fb11c";
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/47308d73-0cd8-4d45-be27-1f5a7e06dfea";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/FC6A-A214";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/b2374756-571b-4fb6-9261-9796b93578f9"; }];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
