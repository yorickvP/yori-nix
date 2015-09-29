{ config, lib, pkgs, ... }:

let
  powersw = "/etc/powerdown/powerswitch";
  powerswpath = [ pkgs.hdparm pkgs.iw pkgs.gawk pkgs.kmod config.system.sbin.modprobe ];
in
{

  services.udev.path=powerswpath;
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${powersw}"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${powersw}"
  '';

  systemd.services.powerswitch = {
    enable = true;
    wantedBy = [ "multi-user.target" "suspend.target" ];
    after = [ "suspend.target" "display-manager.service" ];
    description = "Run powerswitch sometimes";
    path = powerswpath;
    preStart = "sleep 4s";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = powersw;
    };
  };
}
