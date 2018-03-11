{ config, pkgs, lib, ... }:
let
  cfg = config.services.yorick.gogs;
in
{
  options.services.yorick.gogs = with lib; {
    enable = mkEnableOption "gogs";
    dir = mkOption { type = types.string; default = "/var/gogs"; };
    port = mkOption { type = types.int; default = 8001; };
    vhost = mkOption { type = types.string; };
  };
  config = lib.mkIf cfg.enable {
    
    users.extraUsers.git = { home = cfg.dir; extraGroups = [ "git" ]; useDefaultShell = true;};
    users.extraGroups.git = { };
    services.gogs = rec {
      enable = true;
      user = "git";
      group = "git";
      database.user = "root";
      stateDir = cfg.dir;
      repositoryRoot = "${stateDir}/gogs-repositories";
      rootUrl = "https://${cfg.vhost}/";
      httpAddress = "localhost";
      httpPort = cfg.port;
      extraConfig = ''
        [service]
        REGISTER_EMAIL_CONFIRM = false
        ENABLE_NOTIFY_MAIL = false
        DISABLE_REGISTRATION = true
        REQUIRE_SIGNIN_VIEW = false
        [picture]
        DISABLE_GRAVATAR = false
        AVATAR_UPLOAD_PATH = ${cfg.dir}/data/avatars
        [mailer]
        ENABLED = false
      '';
      domain = cfg.vhost;
    };
    users.extraUsers.gogs.createHome = lib.mkForce false;
    services.nginx.virtualHosts.${cfg.vhost} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString cfg.port}";
        extraConfig = ''
          proxy_buffering off;
        '';
      };
    };
  };
}
