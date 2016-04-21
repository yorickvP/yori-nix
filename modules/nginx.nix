{ config, lib, pkgs, ... }:
let
cfg = config.nginxssl;
sslcfg = dir: ''
    ssl on;
  	ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
    ssl_certificate_key ${dir}/key.pem;
    ssl_certificate ${dir}/fullchain.pem;
    ssl_trusted_certificate ${dir}/fullchain.pem;
    ssl_dhparam /etc/nginx/dhparam.pem;
    ssl_protocols TLSv1.1 TLSv1.2;
    # ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';
    ssl_prefer_server_ciphers on;
    add_header Strict-Transport-Security max-age=15768000;
    ssl_stapling on;
    ssl_stapling_verify on;
'';

makeChallenges = servername: key_webroot: ''
	server {
		listen 80;
		server_name ${servername};
		server_tokens off;
		location /.well-known/acme-challenge {
			default_type text/plain;
			alias ${key_webroot}/.well-known/acme-challenge;
		}
	}
'';
makeServerBlock = servername: {key_root, key_webroot, contents, ...}: ''
	server {
		listen 80;
		server_name ${servername};
		server_tokens off;
		location /.well-known/acme-challenge {
			default_type text/plain;
			alias ${key_webroot}/.well-known/acme-challenge;
		}
		location / {
			rewrite ^(.*) https://$host$1 permanent;
		}
	}
	server {
		listen       443;
		server_name  ${servername};
		server_tokens off;
		${sslcfg key_root}
		${contents}
	}
'';
#vhosts = with lib; unique (concatMap (splitString " ") (attrNames cfg.servers));
servopts = {...}: {
	options = {
		key_webroot = mkOption {
			type = types.string;
			description = "The path where the acme challenge is stored";
		};
		key_root = mkOption {
			type = types.string;
			description = "The path where the SSL keys are stored";
		};
		contents = mkOption {
			type = types.string;
			description = "Extra server block contents, like location blocks";
			example = "location / {}";
		};
	};
};
inherit (lib) mkEnableOption mkOption types mkIf;
in
{
    options.nginxssl = {
    	enable = mkEnableOption "enable new nginx module";
    	no_vhost_keydir = mkOption {
    		type = types.string;
    		default = "/etc/sslcerts/no_vhost";
    		description = "The path where the SSL keys for the default are stored (can and will be self-signed)";
    	};
        servers = mkOption {
        	type = types.attrsOf types.optionSet;
        	description = "The servers to host";
        	default = {};
        	example = {"git.domain.com" = {
        			contents = "location / {}";
        			key_root = "/var/lib/acme/git.domain.com";
        			key_webroot = "/etc/sslcerts/acmeroot";
	        	};
	        };
	        options = [ servopts ];
        };
        challenges = mkOption {
        	type = types.attrsOf types.string;
        	default = [];
        	example = {"mail.domain.com" = "/var/lib/acme/mail.domain.com";};
        	description = "Other domains to host challenges for";
        };
    };
    config = mkIf cfg.enable {
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
	      # the default thing, for if no vhost is given
	      # generate default.pem and default.key manually
	      # and self-sign, if you feel like it
	      server {
	      	listen 80 default_server;
	      	server_name "";
	      	location / {
	      		rewrite ^(.*) https://$host$1 permanent;
	      	}
	      }
	      server {
	        listen       443 default_server spdy deferred;
	        server_name  "";

	        ${sslcfg cfg.no_vhost_keydir}

	        location / {
	          root   ${pkgs.nginx}/html;
	          index  index.html index.htm;
	        }

	        location = /50x.html {
	          root   ${pkgs.nginx}/html;
	        }
	      }

	      ${lib.concatStringsSep "\n" (lib.mapAttrsToList makeChallenges cfg.challenges)}

	      ${lib.concatStringsSep "\n" (lib.mapAttrsToList makeServerBlock cfg.servers)}

	    '';
	  };
	  networking.firewall.allowedTCPPorts = [80 443];
	  system.activationScripts.nginxdhparams =
	    ''
	      if ! [[ -e /etc/nginx/dhparam.pem ]]; then
	        mkdir -p /etc/nginx/
	        ${pkgs.openssl}/bin/openssl dhparam -out /etc/nginx/dhparam.pem 2048
	      fi
	      dir=${cfg.no_vhost_keydir}
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
