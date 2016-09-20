{ config, pkgs, lib, ... }:
let
cfg = config.services.backup;
inherit (lib) mkEnableOption mkOption types mkIf
flip mapAttrs' nameValuePair;
in
{

  options.services.backup = {
    enable = mkOption { type = types.bool; default = false; };
    backups = mkOption {
      type = types.loaOf types.optionSet;
      options = {
        dir = mkOption { type = types.str; };
        user = mkOption { type = types.str; };
        remote = mkOption { type = types.str; };
        keyfile = mkOption { type = types.str; };
        exclude = mkOption { type = types.str; default = ""; };
        interval = mkOption { type = types.str; default = "weekly"; };
      };
    };
  };
  config = mkIf cfg.enable {
    systemd.services = let
      sectionToService = name: data: with data; {
        description = "Back up ${name}";
        serviceConfig = {
          IOSchedulingClass="idle";
          User=user;
          #Type = "oneshot";
        };
        script = ''
          source ${keyfile}
          ${pkgs.duplicity}/bin/duplicity ${dir} ${remote} \
            --ssl-cacert-file /etc/ssl/certs/ca-bundle.crt \
            --encrypt-key ${user} \
            --exclude-filelist ${pkgs.writeText "dupignore" exclude} \
            --asynchronous-upload \
            --volsize 100 \
            --allow-source-mismatch
        '';
        after = ["network.target" "network-online.target"];
        wants = ["network-online.target"];
      };
  in flip mapAttrs' cfg.backups (name: data: nameValuePair
    ("backup-${name}")
    (sectionToService name data));
  systemd.timers = flip mapAttrs' cfg.backups (name: data: nameValuePair
    ("backup-${name}")
    ({
      description = "Periodically backups ${name}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = data.interval;
        Unit = "backup-${name}.service";
      };
    }));
  };
}
