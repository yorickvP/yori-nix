# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      ./graphical.nix
    ];


  # no, not that Ascanius.
  networking.hostName = "ascanius";

  # GOTTA GO FASTER
  # this pulls in systemd-udevd-settle, which slows down boot
  systemd.services.scsi-link-pm.enable = false;
  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs : {
      bluez = pkgs.bluez5;
    };
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    (texLiveAggregationFun { paths = [ texLive texLiveExtra texLiveBeamer lmodern ]; })
    atool
    bc
    git
    hdparm
    htop
    lm_sensors
    mtr
    ncdu
    sl # v important.
    smartmontools
    unzip zip
    wget
  ];

  virtualisation.virtualbox.host.enable = true;

  systemd.services.powerswitch = {
    enable = true;
    wantedBy = [ "multi-user.target" "suspend.target" ];
    after = [ "suspend.target" "display-manager.service" ];
    description = "Run powerswitch sometimes";
    path = [ pkgs.hdparm pkgs.iw pkgs.gawk pkgs.kmod config.system.sbin.modprobe ];
    preStart = "sleep 2s";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''/etc/powerdown/powerswitch'';
    };
  };

  # TODO: cups.

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.yorick = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = ["wheel"];
  };

  # not using ipv6 for now
  networking.enableIPv6 = false;

  nix.binaryCaches = [
    https://hydra.nixos.org
  ];
  nix.trustedBinaryCaches = config.nix.binaryCaches;


}
