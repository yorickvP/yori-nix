{ config, pkgs, lib, ... }:
let
  gitHome = "/var/gogs";
  gogs = pkgs.callPackage ../packages/gogs.nix { };
  gogsPort = 8001;
  domain = config.gogs.domain;
  gogsConfig = pkgs.writeText "gogs.ini" ''
APP_NAME = Gogs: Go Git Service
RUN_USER = git
RUN_MODE = prod
[database]
DB_TYPE = sqlite3
HOST = 127.0.0.1:3306
NAME = gogs
USER = root
PASSWD = 
SSL_MODE = disable
PATH = ${gitHome}/data/gogs.db
[repository]
ROOT = ${gitHome}/gogs-repositories
[server]
DOMAIN = ${domain}
HTTP_PORT = ${toString gogsPort}
ROOT_URL = https://${domain}/
DISABLE_SSH = false
SSH_PORT = 22
OFFLINE_MODE = false
[mailer]
ENABLED = false
[service]
REGISTER_EMAIL_CONFIRM = false
ENABLE_NOTIFY_MAIL = false
DISABLE_REGISTRATION = true
REQUIRE_SIGNIN_VIEW = false
[picture]
DISABLE_GRAVATAR = false
AVATAR_UPLOAD_PATH = ${gitHome}/data/avatars
[session]
PROVIDER = file
[log]
ROOT_PATH = ${gitHome}/logs
MODE = file
LEVEL = Info
[security]
INSTALL_LOCK = true
'';
inherit (lib) mkOption types;
in
{
    imports = [./le_nginx.nix];
    options.gogs = {
      domain = mkOption {
        type = types.string;
        description = "The domain to run the servers on";
        default = {};
        example = "git.domain.com";
      };
    };
    config = 
{
  users.extraUsers.git = { home = gitHome; extraGroups = [ "git" ]; useDefaultShell = true;};
  users.extraGroups.git = { };
  systemd.services.gogs = {
    path = with pkgs; [ git openssh bash ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      User = "git";
      Group = "git";
      ExecStart = "${gogs}/gogs web -c ${gogsConfig}";
      WorkingDirectory = gitHome;
    };
  };
  le_nginx.servers.${domain} = ''
    location / {
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header X-Forwarded-Server $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_redirect off;
      proxy_buffering off;
      proxy_pass http://gogs;
      client_max_body_size 30M;
      break;
    }
  '';
  services.nginx.httpConfig = ''
    upstream gogs {
      server 127.0.0.1:${toString gogsPort};
    }
  '';
};
}
