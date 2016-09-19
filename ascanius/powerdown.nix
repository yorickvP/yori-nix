{ config, lib, pkgs, ... }:

let
  pd = pkgs.callPackage ./powerdown {};
  powersw = "${pd}/bin/powerswitch";
in
{

  # the scripts are pretty heavily modified.
  # from https://github.com/march-linux/powerdown
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${powersw}"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${powersw}"
  '';

  systemd.services.powerswitch = {
    enable = true;
    wantedBy = [ "multi-user.target" "suspend.target" ];
    after = [ "suspend.target" "display-manager.service" ];
    description = "Run powerswitch sometimes";
    preStart = "sleep 4s";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = powersw;
    };
  };
}
