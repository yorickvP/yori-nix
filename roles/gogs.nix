{ config, pkgs, lib, ... }:
let
  gitHome = "/var/gogs";
  gogsPort = 8001;
  domain = "git.yori.cc";
in
{
  imports = [
    ../modules/nginx.nix
  ];

  users.extraUsers.git = { home = gitHome; extraGroups = [ "git" ]; useDefaultShell = true;};
  users.extraGroups.git = { };
  services.gogs = rec {
    enable = true;
    user = "git";
    group = "git";
    database.user = "root";
    stateDir = gitHome;
    repositoryRoot = "${stateDir}/gogs-repositories";
    rootUrl = "https://${domain}/";
    httpAddress = "localhost";
    httpPort = gogsPort;
    extraConfig = ''
      [service]
      REGISTER_EMAIL_CONFIRM = false
      ENABLE_NOTIFY_MAIL = false
      DISABLE_REGISTRATION = true
      REQUIRE_SIGNIN_VIEW = false
      [picture]
      DISABLE_GRAVATAR = false
      AVATAR_UPLOAD_PATH = ${gitHome}/data/avatars
      [mailer]
      ENABLED = false
      [session]
      PROVIDER = file
      [log]
      ROOT_PATH = ${gitHome}/logs
      MODE = file
      LEVEL = Info
      [server]
      DISABLE_ROUTER_LOG  = true
    '';
    inherit domain;
  };
  users.extraUsers.gogs.createHome = lib.mkForce false;
  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString gogsPort}";
      extraConfig = ''
        proxy_buffering off;
      '';
    };
  };
}
