{ config, lib, pkgs, ... }:

let
  secrets = import <secrets>;
  yoricc = import ../packages/yori-cc.nix;
  acmeWebRoot = "/etc/sslcerts/acmeroot";
  acmeKeyDir = "${config.security.acme.directory}/yori.cc";
in
{
	imports = [
    ../modules/nginx.nix
  ];
  # website + lets encrypt challenge hosting
  nginxssl = {
    enable = true;
    challenges."${config.networking.hostName}" = acmeWebRoot;
    servers."yori.cc" = {
      key_root = acmeKeyDir;
      key_webroot = acmeWebRoot;
      contents = ''
        location / {
          rewrite ^(.*) https://yorickvanpelt.nl$1 permanent;
        }
      '';
    };
    servers."yorickvanpelt.nl" = {
      key_root = acmeKeyDir;
      key_webroot = acmeWebRoot;
      contents = ''
        location / {
          root ${yoricc}/web;
        }
      '';
    };
  };


  # Let's Encrypt configuration.
  security.acme.certs."yori.cc" =
    { email = secrets.email;
      extraDomains = {
        "${config.networking.hostName}" = null;
        "yorickvanpelt.nl" = null;
      };
      webroot = acmeWebRoot;
      postRun = ''systemctl reload nginx.service dovecot2.service postfix.service
          systemctl restart prosody.service
      '';
    };
}
