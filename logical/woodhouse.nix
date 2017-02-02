# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  secrets = import <secrets>;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ../physical/nuc.nix
      ../roles/common.nix
      ../roles/collectd.nix
      ../modules/tor-hidden-service.nix
      ../roles/graphical.nix
    ];

  networking.hostName = secrets.hostnames.woodhouse;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "16.09";


  services.xserver = {
  	# displayManager.slim.autoLogin = true; # TODO: debug this
  };



  services.tor.hiddenServices = [
    { name = "ssh";
      port = 22;
      hostname = secrets.tor_hostnames."ssh.woodhouse";
      private_key = "/run/keys/torkeys/ssh.woodhouse.key"; }
  ];

  system.fsPackages = [ pkgs.sshfsFuse ];
  fileSystems."/mnt/frumar" = {
    # todo:  "ServerAliveCountMax=3" "ServerAliveInterval=30"

    device = "${pkgs.sshfsFuse}/bin/sshfs#yorick@" + secrets.hostnames.frumar + ":/data/yorick";
    fsType = "fuse";
    options = ["noauto" "x-systemd.automount" "_netdev" "users" "idmap=user"
               "defaults" "allow_other" "transform_symlinks" "default_permissions"
               "uid=1000"
               "reconnect" "IdentityFile=/root/.ssh/id_sshfs"];
  };
  fileSystems."/mnt/alphonse" = {
    device = "${pkgs.sshfsFuse}/bin/sshfs#yorick@quassel.rasusan.nl:/mnt/storinator";
    fsType = "fuse";
    options = ["noauto" "x-systemd.automount" "_netdev" "users" "idmap=user"
               "defaults" "allow_other" "transform_symlinks" "default_permissions"
               "uid=1000"
               "reconnect" "IdentityFile=/root/.ssh/id_sshfs" "port=15777"];
  };

  networking.firewall.allowedTCPPorts = [7 8080 9090 9777]; # kodi

}
