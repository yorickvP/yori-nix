{ config, pkgs, lib, ... }:
let secrets = import <secrets>;
acmeKeyDir = "${config.security.acme.directory}/yori.cc";
in
{
  imports = [
    ../modules/mailz.nix
    ../modules/backup.nix
  ];
  config = {
    # email
    services.mailz = {
      domain = config.networking.hostName;
      keydir = acmeKeyDir;
      mainUser = "yorick";
      users = {
        yorick = with secrets; {
          password = yorick_mailPassword;
          domains = email_domains;
        };
      };
    };
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
