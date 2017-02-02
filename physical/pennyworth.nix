{ config, lib, pkgs, ... }:
let
  ipconf = (import <secrets>).ipconf.${config.networking.hostName};
in
{
  imports = [ ../modules/nixos-in-place.nix ];
  "nixos-in-place" = {
    enable = true;
    rootfs = "/dev/disk/by-uuid/7165e542-0995-474c-a228-9592339e0604";
    swapfs = "/dev/disk/by-uuid/baaf824a-bee0-4037-a237-3a69f1db7985";
  };
  # fs layout:
  # before: /nixos/nix/* /boot/grub/menu.lst
  # after:  /nix/* /old-root/boot/grub/menu.lst
  boot = {
    # use grub 1, don't install
    loader.grub = {
      version = 1;
      extraPerEntryConfig = "root (hd0,0)"; # do we need this?
      mirroredBoots = [{
        path = "/old-root/boot";
        devices = ["nodev"];
      }];
      splashImage = null;
    };
    initrd.availableKernelModules = [ "xen_blkfront" ];
  };
  sound.enable = false;
  networking = {
    usePredictableInterfaceNames = false; # only eth0
    interfaces.eth0 = {
      useDHCP = false;
      inherit (ipconf) ip4 ip6;
    };
    inherit (ipconf) nameservers;
    # ideally, it should add a route for this automatically
    #defaultGateway  = ipconf.gateway4;
    #defaultGateway6 = ipconf.gateway6;
  };
  systemd.services."network-setup".postStart = with ipconf; ''
    ip route add ${gateway4} dev eth0 || true
    ip route add default via ${gateway4} || true
    ip -6 route add ${gateway6} dev eth0 || true
    ip -6 route add default via ${gateway6} || true
  '';
  nix.maxJobs = lib.mkDefault 2;
}
