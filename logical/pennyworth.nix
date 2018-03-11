# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports = [
    <yori-nix/physical/kassala.nix>
    <yori-nix/roles/server.nix>
    ../modules/muflax-blog.nix
  ];

  networking.enableIPv6 = lib.mkOverride 30 true;

  system.stateVersion = "16.03";
  
  services.nginx.enable = true;
  services.yorick = {
    website = { enable = true; vhost = "yorickvanpelt.nl"; };
    mail = {
      enable = true;
      mainUser = "yorick";
      users.yorick = {
        password = (import <yori-nix/secrets.nix>).yorick_mailPassword;
        domains = ["yori.cc" "yorickvanpelt.nl"];
      };
    };
    xmpp = {
      enable = true;
      vhost = "yori.cc";
      admins = [ "yorick@yori.cc" ];
    };
  };
  services.nginx.virtualHosts."yori.cc" = {
    enableACME = true;
    forceSSL = true;
    globalRedirect = "yorickvanpelt.nl";
  };




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
