{ config, pkgs, lib, ... }:
{
  imports = [../modules/le_nginx.nix];
  config = {
    users.extraUsers.public = {
      home = "/home/public";
      useDefaultShell = true;
      openssh.authorizedKeys.keys = with (import ../sshkeys.nix); [public];
      createHome = true;
    };
    le_nginx.servers."pub.yori.cc" = ''
      location / {
        root /home/public/public;
        index index.html;
      }
    '';
  };
}
