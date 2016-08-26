# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
let
  secrets = import <secrets>;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../roles/common.nix
      ../modules/tor-hidden-service.nix
      ../roles/graphical.nix
    ];

  # Use the gummiboot efi boot loader.
  boot.loader.gummiboot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = secrets.hostnames.woodhouse;

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };


  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;


  # root password is useful from console, ssh has password logins disabled
  users.extraUsers.root.hashedPassword = secrets.pennyworth_hashedPassword; # TODO: generate own


  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.kdm.enable = true;
  # services.xserver.desktopManager.kde4.enable = true;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "16.03";


  services.redshift.enable = lib.mkOverride 30 false;
  services.xserver = {
  	#windowManager.i3.enable = true;
  	desktopManager.e19.enable = true;
  	displayManager.slim.autoLogin = true;
  };

  users.extraUsers.yorick.hashedPassword = secrets.yorick_hashedPassword;

  environment.systemPackages = with pkgs; [
    btrfs-progs
  ];
  services.tor.hiddenServices = [
    { name = "ssh";
      port = 22;
      hostname = secrets.tor_hostnames."ssh.woodhouse";
      private_key = "/run/keys/torkeys/ssh.woodhouse.key"; }
  ];

  system.fsPackages = [ pkgs.sshfsFuse ];
  fileSystems."/mnt/frumar" = {
    # todo:  "ServerAliveCountMax=3" "ServerAliveInterval=30"

    device = "${pkgs.sshfsFuse}/bin/sshfs#yorick@" + secrets.hostnames.frumar + ":/data/yorick";
    fsType = "fuse";
    options = ["noauto" "x-systemd.automount" "_netdev" "users" "idmap=user"
               "defaults" "allow_other" "transform_symlinks" "default_permissions"
               "uid=1000"
               "reconnect" "IdentityFile=/root/.ssh/id_sshfs"];
  };
  fileSystems."/mnt/alphonse" = {
    device = "${pkgs.sshfsFuse}/bin/sshfs#yorick@quassel.rasusan.nl:/mnt/storinator";
    fsType = "fuse";
    options = ["noauto" "x-systemd.automount" "_netdev" "users" "idmap=user"
               "defaults" "allow_other" "transform_symlinks" "default_permissions"
               "uid=1000"
               "reconnect" "IdentityFile=/root/.ssh/id_sshfs" "port=15777"];
  };

  networking.firewall.allowedTCPPorts = [7 8080 9090 9777]; # kodi

}
