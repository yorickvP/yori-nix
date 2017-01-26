# use together with ./collectd.nix
{ config, pkgs, lib, ...}:
let
  secrets = import <secrets>;
  grafana_port = 3000;
  domain = "graphs.yori.cc";
in
{
  networking.firewall.allowedUDPPorts = [25826];
  services.influxdb = {
    enable = true;
    extraConfig = {
      collectd = [{
        enabled = true;
        typesdb = "${pkgs.collectd}/share/collectd/types.db";
        database = "collectd_db";
        "security-level" = "sign";
        "auth-file" = pkgs.writeText "collectd_auth"
          (builtins.concatStringsSep "\n" (lib.mapAttrsToList (n: p: "${n}: ${p}") secrets.influx_pass) + "\n");
        port = 25826;
      }];
    };
  };
  services.grafana = {
    enable = true;
    inherit domain;
    rootUrl = "https://${domain}/";
    port = grafana_port;
  };
  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString grafana_port}";
    };
  };

}
