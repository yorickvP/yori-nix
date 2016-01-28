{ config, lib, pkgs, ... }:

{
  imports = [ ];

  swapDevices =
    [ { device = "/dev/disk/by-uuid/be7625e5-2e2c-41f2-8d5f-331f90980b9e"; }
    ];

  boot = {
	  kernelModules = [ ];
	  extraModulePackages = [ ];
	  kernelParams = ["boot.shell_on_fail"];
	  loader.grub.device = "/dev/sda";
	  loader.grub.storePath = "/nixos/nix/store";
	  initrd.availableKernelModules = [ "ata_piix" "vmw_pvscsi" "floppy" ];
	  initrd.supportedFilesystems = [ "ext4" ];
	  initrd.postDeviceCommands = ''
	    mkdir -p /mnt-root/old-root ;
	    mount -t ext4 /dev/mapper/CAC_VG-CAC_LV /mnt-root/old-root ;
	  '';
  };

  fileSystems = {
    "/" = {
      device = "/old-root/nixos";
      fsType = "none";
      "options" = "bind";
    };
    "/old-root" = {
      device = "/dev/mapper/CAC_VG-CAC_LV";
      fsType = "ext4";
    };
  };
  networking = {
    interfaces.enp2s0 = {
    	useDHCP = false;
    	ipAddress = "104.233.92.136";
    	prefixLength = 24;
    };
    defaultGateway = "104.233.92.1";
    nameservers = ["8.8.8.8"];
  };
  nix.maxJobs = 1;

}
