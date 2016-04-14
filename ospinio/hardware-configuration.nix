{ config, lib, pkgs, ... }:
let
  ipconf = (import <secrets>).ipconf.${config.networking.hostName};
in
{
  imports = [ ../nixos-in-place.nix ];
  "nixos-in-place" = {
    enable = true;
    rootfs = "/dev/mapper/CAC_VG-CAC_LV";
    swapfs = "/dev/disk/by-uuid/be7625e5-2e2c-41f2-8d5f-331f90980b9e";
  };
  boot = {
    loader.grub.device = "/dev/sda";
    initrd.availableKernelModules = [ "ata_piix" "vmw_pvscsi" "floppy" ];
  };

  networking = {
    interfaces.enp2s0 = {
      useDHCP = false;
      inherit (ipconf) ip4 ip6;
    };
    inherit (ipconf) nameservers;
    defaultGateway  = ipconf.gateway4;
    #defaultGateway6 = ipconf.gateway6;
  };

  nix.maxJobs = 1;

}
