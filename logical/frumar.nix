{ config, pkgs, ... }:
{
  imports = [ 
    <yori-nix/physical/fractal.nix>
    <yori-nix/roles/server.nix>
  ];


  system.stateVersion = "15.09";

  services.nginx.enable = true;
  services.yorick = {
    public = { enable = true; vhost = "pub.yori.cc"; };
    gogs   = { enable = true; vhost = "git.yori.cc"; };
    quassel.enable = true;
  };
  

}
