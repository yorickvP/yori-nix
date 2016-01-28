{ config, lib, pkgs, ... }:
let
cfg = config.le_nginx;
sslcfg = {fullchain ? "fullchain.pem", key ? "key.pem"}: ''
    ssl on;
  	ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
    ssl_certificate_key /etc/sslcerts/${key};
    ssl_certificate /etc/sslcerts/${fullchain};
    ssl_dhparam /etc/nginx/dhparam.pem;
    ssl_protocols TLSv1.1 TLSv1.2;
    # ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';
    ssl_prefer_server_ciphers on;
    add_header Strict-Transport-Security max-age=15768000;
    ssl_stapling on;
    ssl_stapling_verify on;
'';
makeServerBlock = servername: locationblock: ''
  server {
    listen       443;
    server_name  ${servername};
    ${sslcfg {}}
    ${locationblock}
  }
'';
vhosts = with lib; unique (concatMap (splitString " ") (attrNames cfg.servers));
inherit (lib) mkEnableOption mkOption types mkIf;
in
{
	# todo: the problem here is that nginx will refuse to start initlaiiy
	# because the SSL cert will be missing
	# so you have to temporarily disable the ssl
    options.le_nginx = {
    	enable = mkEnableOption "enable new nginx module";
    	enable_ssl = mkEnableOption "enable the SSL blocks";
        servers = mkOption {
        	type = types.attrsOf types.string;
        	description = "The servers to host";
        	default = {};
        	example = {"git.domain.com" = "location / {}";};
        };
        email = mkOption {
            type = types.string;
            description = "email address to pass to LE";
        };
    };
    config = mkIf cfg.enable {
    	systemd.services.letsencrypt = {
	      path = [ pkgs.simp_le ];
	      restartIfChanged = true;
	      serviceConfig = {
	          Type = "oneshot";
	      };
	      script = ''
	          mkdir -p /etc/sslcerts/acmeroot
	          cd /etc/sslcerts
	          simp_le ${lib.concatMapStringsSep " " (x: "-d " + x) vhosts} --default_root $PWD/acmeroot -f fullchain.pem -f key.pem -f account_key.json --email ${cfg.email}
	      '';
	      startAt = "04:00";
	  };
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

	      server_tokens off;

	      ssl_session_cache   shared:SSL:10m;
	      ssl_session_timeout 10m;


	      gzip  on;

	      server {
		      listen 80 default_server;
		      server_name ${lib.concatStringsSep " " vhosts};
		      location /.well-known/acme-challenge {
		          default_type text/plain;
		          alias /etc/sslcerts/acmeroot/.well-known/acme-challenge;
		      }
		      location / {
		          rewrite ^(.*) https://$host$1 permanent;
		      }
	      }
	      '' + lib.optionalString cfg.enable_ssl ''

	      # the default thing, for if no vhost is given
	      # generate default.pem and default.key manually
	      # and self-sign, if you feel like it
	      server {
	        listen       443 default_server;
	        server_name  "";

	        ${sslcfg {fullchain = "default.crt"; key = "default.key";}}

	        location / {
	          root   ${pkgs.nginx}/usr/share/nginx/html;
	          index  index.html index.htm;
	        }

	        location = /50x.html {
	          root   ${pkgs.nginx}/usr/share/nginx/html;
	        }
	      }

	      ${lib.concatStringsSep "\n" (lib.mapAttrsToList makeServerBlock cfg.servers)}

	    '';
	  };
	  networking.firewall.allowedTCPPorts = [80 443];
	};


}
