# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let yoricc = import ../packages/yori-cc.nix;
in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../roles/common.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda";

  networking.hostName = (import <secrets>).hostnames.ospinio;


  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "15.09";

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
  networking.firewall.allowedTCPPorts = [22 80];
}
