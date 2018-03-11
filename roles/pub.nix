{ config, pkgs, lib, ... }:
let cfg = config.services.yorick.public; in
{
  options.services.yorick.public = {
    enable = lib.mkEnableOption "public hosting";
    vhost = lib.mkOption { type = lib.types.string; };
  };
  #imports = [../modules/nginx.nix];
  config = lib.mkIf cfg.enable {
    users.extraUsers.public = {
      home = "/home/public";
      useDefaultShell = true;
      openssh.authorizedKeys.keys = with (import ../sshkeys.nix); [public];
      createHome = true;
    };
    services.nginx.virtualHosts.${cfg.vhost} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        root = "/home/public/public";
        index = "index.html";
      };
    };
  };
}
