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
      ./hardware-configuration.nix
      ../roles/common.nix
      ../modules/mailz.nix
      ../modules/nginx.nix
      ../modules/tor-hidden-service.nix
  ];

  networking.hostName = secrets.hostnames.pennyworth;

  environment.noXlibs = true;

  services.openssh.enable = true;
  networking.enableIPv6 = lib.mkOverride 30 true;

  system.stateVersion = "16.03";

  # root password is useful from console, ssh has password logins disabled
  users.extraUsers.root.hashedPassword = secrets.pennyworth_hashedPassword;

  # email
  services.mailz = {
    domain = config.networking.hostName;
    keydir = acmeKeyDir;
    domains = secrets.email_domains;
    users = {
      yorick = {
        password = secrets.yorick_mailPassword;
        aliases = ["postmaster" "me" "ik" "info" "~"];
      };
    };
  };

  # website + lets encrypt challenge hosting
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
      postRun = ''systemctl reload nginx.service dovecot2.service opensmtpd.service
          systemctl restart prosody.service
      '';
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
      hostname = "/run/keys/torkeys/ssh.pennyworth.hostname";
      private_key = "/run/keys/torkeys/ssh.pennyworth.key"; }
  ];

  # XMPP
  services.prosody = let
    # TODO: this should be in nixpkgs
    prosodyModules = pkgs.fetchhg {
      name = "prosody-modules-22042016";
      rev = "e0b8b8a50013";
      sha256 = "06qd46bmwjpzrygih91fv7z7g8z60kn0qyr7cf06a57a28117wdy";
      url = "https://hg.prosody.im/prosody-modules/";
    };
  in {
    enable = true;

    allowRegistration = false;
    extraModules = [ "private" "vcard" "privacy" "compression" "muc" "pep" "adhoc" "lastactivity" "admin_adhoc" "blocklist" "mam" "carbons" "smacks"];
    virtualHosts.yoricc = {
      enabled = true;
      domain = "yori.cc";
      ssl = {
        key = "/var/lib/prosody/keys/key.pem";
        cert = "/var/lib/prosody/keys/fullchain.pem";
      };
    };
    # TODO: Component "chat.yori.cc" "muc" # also proxy65 and pubsub?
    extraConfig = ''
      plugin_paths = { "${prosodyModules}" }
      use_libevent = true
      s2s_require_encryption = true
      c2s_require_encryption = true
      archive_expires_after = "never"
      storage = {
        archive2 = "sql";
      }
    '';

    admins = [ "yorick@yori.cc"];
  };
  nixpkgs.config.packageOverrides = pkgs:
    # FIXME: ugly hacks!
    { prosody = pkgs.prosody.override { withZlib = true; luazlib = luadbi; };
    };
  systemd.services.prosody.serviceConfig.PermissionsStartOnly = true;
  systemd.services.prosody.preStart = ''
      mkdir -m 0700 -p /var/lib/prosody/keys
      cp ${acmeKeyDir}/key.pem ${acmeKeyDir}/fullchain.pem /var/lib/prosody/keys
      chown -R prosody:prosody /var/lib/prosody
  '';
  networking.firewall.allowedTCPPorts = [5222 5269];
}
