# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let secrets = import <secrets>;
  acmeWebRoot = "/etc/sslcerts/acmeroot";
  acmeKeyDir = "${config.security.acme.directory}/git.yori.cc";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../roles/common.nix
     ../modules/nginx.nix
      ../modules/gogs.nix # todo: better separation here
      ../modules/tor-hidden-service.nix
      ../roles/quassel.nix
      ../roles/pub.nix
      ../roles/collectd.nix
    ];


  networking.hostName = secrets.hostnames.frumar;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "15.09";

  gogs.domain = "git.yori.cc";
  nginxssl.enable = true;

  # hidden SSH service

  services.tor.hiddenServices = [
    { name = "ssh";
      port = 22;
      hostname = secrets.tor_hostnames."ssh.frumar";
      private_key = "/run/keys/torkeys/ssh.frumar.key"; }
  ];
}