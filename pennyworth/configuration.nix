# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  secrets = import <secrets>;
  yoricc = import ../packages/yori-cc.nix;
  acmeWebRoot = "/etc/sslcerts/acmeroot";
  acmeKeyDir = "${config.security.acme.directory}/yori.cc";
in
{
  imports = [
      ./hardware-configuration.nix
      ../roles/common.nix
      ../modules/nginx.nix
  ];

  networking.hostName = secrets.hostnames.pennyworth;

  services.openssh.enable = true;
  networking.enableIPv6 = lib.mkOverride 30 true;

  system.stateVersion = "16.03";

  # root password is useful from console, ssh has password logins disabled
  users.extraUsers.root.hashedPassword = secrets.pennyworth_hashedPassword;


  nginxssl = {
    enable = true;
    challenges."${config.networking.hostName}" = acmeWebRoot;
    servers."yori.cc" = {
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
      };
      webroot = acmeWebRoot;
      postRun = "systemctl reload nginx.service dovecot2.service opensmtpd.service";
    };
  # Generate a dummy self-signed certificate until we get one from
  # Let's Encrypt.
  system.activationScripts.letsEncryptKeys =
    ''
      dir=${acmeKeyDir}
      mkdir -m 0700 -p $dir
      if ! [[ -e $dir/key.pem ]]; then
        ${pkgs.openssl}/bin/openssl genrsa -passout pass:foo -des3 -out $dir/key-in.pem 1024
        ${pkgs.openssl}/bin/openssl req -passin pass:foo -new -key $dir/key-in.pem -out $dir/key.csr \
          -subj "/C=NL/CN=www.example.com"
        ${pkgs.openssl}/bin/openssl rsa -passin pass:foo -in $dir/key-in.pem -out $dir/key.pem
        ${pkgs.openssl}/bin/openssl x509 -req -days 365 -in $dir/key.csr -signkey $dir/key.pem -out $dir/fullchain.pem
      fi
    '';
}
