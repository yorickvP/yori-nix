{ config, pkgs, lib, ... }:
let
  secrets = import <secrets>;
mkFuseMount = device: opts: {
    # todo:  "ServerAliveCountMax=3" "ServerAliveInterval=30"

    device = "${pkgs.sshfsFuse}/bin/sshfs#${device}";
    fsType = "fuse";
    options = ["noauto" "x-systemd.automount" "_netdev" "users" "idmap=user"
               "defaults" "allow_other" "transform_symlinks" "default_permissions"
               "uid=1000"
               "reconnect" "IdentityFile=/root/.ssh/id_sshfs"] ++ opts;
};
in
{
  imports =
    [ # Include the results of the hardware scan.
      ../physical/nuc.nix
      ../roles/common.nix
      # ../roles/collectd.nix
      ../roles/graphical.nix
    ];

  networking.hostName = secrets.hostnames.woodhouse;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "17.09";

  system.fsPackages = [ pkgs.sshfsFuse ];

  fileSystems."/mnt/frumar" = mkFuseMount "yorick@${secrets.hostnames.frumar}:/data/yorick" [];
  fileSystems."/mnt/oxygen" = mkFuseMount "yorick@oxygen.obfusk.ch:" [];
  fileSystems."/mnt/nyamsas" = mkFuseMount "yorick@nyamsas.quezacotl.nl:" ["port=1337"];


  networking.firewall.allowedTCPPorts = [7 8080 9090 9777]; # kodi

}
