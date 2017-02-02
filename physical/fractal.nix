# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_250GB_S21PNXAG441016B";


  fileSystems."/" =
    { device = "/dev/disk/by-uuid/ba95c638-f243-48ee-ae81-0c70884e7e74";
      fsType = "ext4";
      options = ["defaults" "relatime" "discard"];
    };

  swapDevices =
    [ { device = "/dev/disk/by-label/nixos-swap"; }
    ];

  nix.maxJobs = 4;
}