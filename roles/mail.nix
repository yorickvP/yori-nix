{ config, pkgs, lib, ... }:
let
cfg = config.services.yorick.mail;
in
{
  imports = [
    ../modules/mailz.nix
    ../modules/backup.nix
  ];
  options.services.yorick.mail = with lib; {
    enable = mkEnableOption "mail service";
    mainUser = mkOption { type = types.string; };
    users = mkOption {};
  };
  config = lib.mkIf cfg.enable {
    # email
    services.mailz = rec {
      domain = config.networking.hostName;
      keydir = "${config.security.acme.directory}/${domain}";
      inherit (cfg) mainUser users;
    };
    security.acme.certs.${config.networking.hostName}.postRun = ''
      systemctl reload dovecot2.service postfix.service
    '';
    services.backup = {
      enable = true;
      backups = {
        mail = {
          dir = "/var/spool/mail";
          remote = "webdavs://mail@yorickvp.stackstorage.com/remote.php/webdav//mail_bak";
          keyfile = "/var/backup/creds";
          interval = "daily";
        };
      };
    };

  };
}
