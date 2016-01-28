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
    };
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    btrfs-progs
  ];

  virtualisation.virtualbox.host.enable = true;

  users.extraUsers.yorick.hashedPassword = secrets.yorick_hashedPassword;
}
