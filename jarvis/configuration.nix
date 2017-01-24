# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let secrets = import <secrets>;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../roles/common.nix
      ../roles/graphical.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "jarvis"; # Define your hostname.
  # Select internationalisation properties.
  i18n.consoleFont = "latarcyrheb-sun32";

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true; # temp
  # Enable CUPS to print documents.
  services.printing.enable = true;


  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "17.03";

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    btrfs-progs
  ];

  #virtualisation.virtualbox.host.enable = true;

  users.extraUsers.yorick.hashedPassword = secrets.yorick_hashedPassword;
  services.xserver.displayManager.sessionCommands = ''
    gpg-connect-agent /bye
    unset SSH_AGENT_PID
    export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh"
    ${pkgs.xorg.xrandr}/bin/xrandr --dpi 192
  '';
  nix.gc.automatic = pkgs.lib.mkOverride 30 false;

}
