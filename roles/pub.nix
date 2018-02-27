{ config, pkgs, lib, ... }:
{
  #imports = [../modules/nginx.nix];
  config = {
    users.extraUsers.public = {
      home = "/home/public";
      useDefaultShell = true;
      openssh.authorizedKeys.keys = with (import ../sshkeys.nix); [public];
      createHome = true;
    };
    services.nginx.virtualHosts."pub.yori.cc" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        root = "/home/public/public";
        index = "index.html";
      };
    };
  };
}
