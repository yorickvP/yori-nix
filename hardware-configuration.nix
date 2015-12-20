# I'm modifying this file anyways.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
      ./modules/powerdown.nix
    ];

  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
    kernelModules = ["nvidiabl" "kvm-intel"];
    extraModulePackages = [pkgs.linuxPackages.nvidiabl];
    extraModprobeConfig = ''
      options nvidiabl min=0x384 max=0x4650
    '';
  };
  services.xserver.videoDrivers = ["nvidia"];
  services.xserver.synaptics.enable = true;

  networking.wireless.enable = true;
  hardware.bluetooth.enable = true;


  # ideal... doesn't work.
  #services.udev.extraRules = ''
  #   KERNEL=="nvidia_backlight", SUBSYSTEM=="backlight", MODE="666"
  #'';
  # for now
  systemd.services."display-manager".preStart = ''
   chmod a+w $(realpath /sys/class/backlight/nvidia_backlight/brightness) || true
  '';
  # any better ideas to do this?... please? the scripts are pretty heavily modified.
  # from https://github.com/march-linux/powerdown
  services.udev.extraRules = ''
    SUBSYSTEM=="firmware", ACTION=="add", ATTR{loading}="-1"
  '';

  boot.initrd.availableKernelModules = [ "xhci_hcd" "ehci_pci" "ahci" "usbhid" "usb_storage" "btrfs" "dm_crypt" ];
  boot.initrd.luks.devices = [ {
    name = "nix-root-enc";
    device = "/dev/sdb2";
    allowDiscards = true;
  }];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/a21dd1ae-b1ef-47d2-854e-4f561f0bfb4c";
      fsType = "btrfs";
      options = "defaults,relatime,discard";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8a141d3a-4a7f-4ece-9881-b958649e956d";
      fsType = "ext2";
    };

  swapDevices = [ ];
    services.printing = {
      enable = true;
      drivers = [ pkgs.gutenprint ];
    };
  nix.maxJobs = 8;
}
