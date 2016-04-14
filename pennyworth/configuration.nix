# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  secrets = import <secrets>;
  yoricc = import ../packages/yori-cc.nix;
in
{
  imports = [
      ./hardware-configuration.nix
      ../roles/common.nix
  ];

  networking.hostName = secrets.hostnames.pennyworth;

  services.openssh.enable = true;
  networking.enableIPv6 = lib.mkOverride 30 true;

  system.stateVersion = "16.03";

  # root password is useful from console, ssh has password logins disabled
  users.extraUsers.root.hashedPassword = secrets.pennyworth_hashedPassword;


  services.nginx = {
    enable = true;
    httpConfig = ''
      log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                        '$status $body_bytes_sent "$http_referer" '
                        '"$http_user_agent" "$http_x_forwarded_for"';

      access_log  logs/access.log  main;
      sendfile        on;
      #tcp_nopush     on;

      #keepalive_timeout  0;
      keepalive_timeout  65;


      gzip  on;

      server {
        listen       80;
        server_name  "";

        location / {
          root   ${pkgs.nginx}/usr/share/nginx/html;
          index  index.html index.htm;
        }

        location = /50x.html {
          root   ${pkgs.nginx}/usr/share/nginx/html;
        }
      }

      server {
        listen 80;
        server_name yori.cc;
        server_tokens off;
        location / {
          root ${yoricc}/web;
        }
      }

    '';
  };
  networking.firewall.allowedTCPPorts = [80];

}
