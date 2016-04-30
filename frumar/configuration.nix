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
    ];


  networking.hostName = secrets.hostnames.frumar;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "15.09";

  gogs.domain = "git.yori.cc";

  # website + lets encrypt challenge hosting
  nginxssl.enable = true;

  # Let's Encrypt configuration.
  security.acme.certs."git.yori.cc" =
    { email = secrets.email;
      webroot = config.nginxssl.servers."git.yori.cc".key_webroot;
      postRun = "systemctl reload nginx.service";
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

  # hidden SSH service

  services.tor.hiddenServices = [
    { name = "ssh";
      port = 22;
      hostname = secrets.tor_hostnames."ssh.frumar";
      private_key = "/run/keys/torkeys/ssh.frumar.key"; }
  ];
}