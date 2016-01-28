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
      ../modules/le_nginx.nix
      ../modules/gogs.nix # todo: better separation here
      ../roles/quassel.nix
      ../roles/pub.nix
    ];


  networking.hostName = secrets.hostnames.frumar;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "15.09";

  gogs.domain = "git.yori.cc";

  le_nginx.email = secrets.email; # you probably know this, but spam
  le_nginx.enable = true;
  le_nginx.enable_ssl = true;
}