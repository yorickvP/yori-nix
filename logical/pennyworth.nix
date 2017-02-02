# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  secrets = import <secrets>;
  yoricc = import ../packages/yori-cc.nix;
  luadbi = pkgs.callPackage ../packages/luadbi.nix {};
  acmeWebRoot = "/etc/sslcerts/acmeroot";
  acmeKeyDir = "${config.security.acme.directory}/yori.cc";
in
{
  imports = [
      ../physical/kassala.nix
      ../roles/common.nix
      ../roles/collectd.nix
      ../roles/graphs.nix
      ../roles/xmpp.nix
      ../roles/website.nix
      ../roles/mail.nix
      ../modules/tor-hidden-service.nix
      ../modules/muflax-blog.nix
      ../roles/asterisk.nix
  ];

  networking.hostName = secrets.hostnames.pennyworth;

  services.nixosManual.enable = false;

  environment.noXlibs = true;

  networking.enableIPv6 = lib.mkOverride 30 true;

  system.stateVersion = "16.03";
  
  nginxssl.enable = true;

  services.nginx.virtualHosts."pad.yori.cc" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9140";
    };
  };

  # hidden SSH service

  services.tor.hiddenServices = [
    { name = "ssh";
      port = 22;
      hostname = secrets.tor_hostnames."ssh.pennyworth";
      private_key = "/run/keys/torkeys/ssh.pennyworth.key"; }
  ];


  services.muflax-blog = {
    enable = true;
    web-server = {
      port = 9001;
    };
    hidden-service = {
      hostname = "muflax65ngodyewp.onion";
      private_key = "/run/keys/torkeys/http.muflax.key";
    };
  };
}
