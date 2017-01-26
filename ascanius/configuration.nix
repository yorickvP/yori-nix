# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let secrets = import <secrets>;
in
{
  imports =
    [ ./hardware-configuration.nix
      ../roles/common.nix
      ../roles/graphical.nix
      ../modules/tor-hidden-service.nix
    ];

  # no, not that Ascanius.
  networking.hostName = secrets.hostnames.ascanius;

  # GOTTA GO FASTER
  # this pulls in systemd-udevd-settle, which slows down boot
  systemd.services.scsi-link-pm.enable = false;

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs : {
      bluez = pkgs.bluez5;
      # https://github.com/NixOS/nixpkgs/issues/22099
      trustedGrub = pkgs.trustedGrub.overrideDerivation (attr: {NIX_CFLAGS_COMPILE = "-Wno-error";});
    };
  };

  services.openssh.enable = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    btrfs-progs ghostscript
  ];

  virtualisation.virtualbox.host.enable = true;

  users.extraUsers.yorick.hashedPassword = secrets.yorick_hashedPassword;
  services.xserver.displayManager.sessionCommands = ''
    gpg-connect-agent /bye
    unset SSH_AGENT_PID
    export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh"
  '';

  services.tor.hiddenServices = [
    { name = "ssh";
      port = 22;
      hostname = secrets.tor_hostnames."ssh.ascanius";
      private_key = "/run/keys/torkeys/ssh.ascanius.key"; }
  ];
  nix.gc.automatic = pkgs.lib.mkOverride 30 false;
}
