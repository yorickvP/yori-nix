{ config, pkgs, ... }:
let secrets = import <secrets>;
in
{
  imports = [ 
    ../physical/fractal.nix
    ../roles/common.nix
  ];


  networking.hostName = secrets.hostnames.frumar;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "15.09";

  services.nginx.enable = true;
  services.yorick = {
    public = { enable = true; vhost = "pub.yori.cc"; };
    gogs   = { enable = true; vhost = "git.yori.cc"; };
    quassel.enable = true;
  };
  

}
