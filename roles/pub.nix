{ config, pkgs, lib, ... }:
let secrets = import <secrets>;
  acmeWebRoot = "/etc/sslcerts/acmeroot";
  acmeKeyDir = "${config.security.acme.directory}/pub.yori.cc";
in
{
  imports = [../modules/nginx.nix];
  config = {
    users.extraUsers.public = {
      home = "/home/public";
      useDefaultShell = true;
      openssh.authorizedKeys.keys = with (import ../sshkeys.nix); [public];
      createHome = true;
    };
    nginxssl.servers."pub.yori.cc" = {
      key_root = acmeKeyDir;
      key_webroot = "/etc/sslcerts/acmeroot";
      contents = ''
        location / {
          root /home/public/public;
          index index.html;
        }
      '';
    };
    # Let's Encrypt configuration.
    security.acme.certs."pub.yori.cc" =
      { email = secrets.email;
        webroot = config.nginxssl.servers."pub.yori.cc".key_webroot;
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
  };
}
