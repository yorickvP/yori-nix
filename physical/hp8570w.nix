{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    <yori-nix/physical>
    ./hp8570w/powerdown.nix
  ];

  hardware.yorick = { cpu = "intel"; gpu = "nvidia"; laptop = true; };

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # this makes sure my wifi doesn't take a minute to work
  services.udev.extraRules = ''
    SUBSYSTEM=="firmware", ACTION=="add", ATTR{loading}="-1"
  '';

  boot.initrd.availableKernelModules = [ "xhci_hcd" "ehci_pci" "ahci" "usbhid" "usb_storage" ];
  boot.initrd.luks.devices = [ {
    name = "nix-root-enc";
    device = "/dev/sdb2";
    allowDiscards = true;
  }];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/a21dd1ae-b1ef-47d2-854e-4f561f0bfb4c";
      fsType = "btrfs";
      options = ["defaults" "relatime" "discard"];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8a141d3a-4a7f-4ece-9881-b958649e956d";
      fsType = "ext2";
    };



  swapDevices = [ ];

  nix.maxJobs = 8;

  #services.tcsd.enable = true; # it has a TPM. maybe use this?
  #environment.systemPackages = with pkgs; [tpm-tools];
}
