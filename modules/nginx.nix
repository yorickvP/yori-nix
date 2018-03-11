{ config, lib, pkgs, ... }:
let
sslcfg = dir: ''
    ssl on;
    ssl_certificate_key ${dir}/key.pem;
    ssl_certificate ${dir}/fullchain.pem;
    ssl_trusted_certificate ${dir}/fullchain.pem;
    add_header Strict-Transport-Security max-age=15768000;
'';

in
{
  config = lib.mkIf config.services.nginx.enable {
	  services.nginx = {
	    recommendedTlsSettings = true;
	    recommendedGzipSettings = true;
	    recommendedProxySettings = true;
	    recommendedOptimisation = true;
	    serverTokens = false;
	    sslDhparam = "/etc/nginx/dhparam.pem";
      virtualHosts."${config.networking.hostName}" = {
        enableACME = true;
        forceSSL = true;
        default = true;
      };
    };
	  networking.firewall.allowedTCPPorts = [80 443];
	  system.activationScripts.nginxdhparams = ''
	    if ! [[ -e /etc/nginx/dhparam.pem ]]; then
	      mkdir -p /etc/nginx/
	      ${pkgs.openssl}/bin/openssl dhparam -out /etc/nginx/dhparam.pem 2048
	    fi
    '';
	};

}
