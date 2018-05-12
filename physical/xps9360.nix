{ config, lib, pkgs, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ./.
  ];
  hardware.yorick = { cpu = "intel"; gpu = "intel"; laptop = true; };


  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.blacklistedKernelModules = ["psmouse"];


  fileSystems."/" =
    { device = "/dev/disk/by-uuid/a751e4ea-f1aa-48e1-9cbe-423878e29b62";
      fsType = "btrfs";
      options = ["defaults" "relatime" "discard"];
    };

  boot.initrd.luks.devices."nix-crypt" = {
    device = "/dev/disk/by-uuid/320ef81d-283f-4916-ac26-ecfb0f31e549";
    allowDiscards = true;
  };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/0E07-7805";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/d9c4c15b-0e9c-47f6-8675-93b1b8de5f9d"; }
    ];

  nix.maxJobs = lib.mkDefault 4;
  
  # bigger console font
  i18n.consoleFont = "latarcyrheb-sun32";

  hardware.firmware = lib.mkBefore [ pkgs.firmware_qca6174 ];
}
