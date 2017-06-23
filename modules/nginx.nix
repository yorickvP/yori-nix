{ config, lib, pkgs, ... }:
let
cfg = config.nginxssl;
sslcfg = dir: ''
    ssl on;
    ssl_certificate_key ${dir}/key.pem;
    ssl_certificate ${dir}/fullchain.pem;
    ssl_trusted_certificate ${dir}/fullchain.pem;
    add_header Strict-Transport-Security max-age=15768000;
'';

makeChallenges = servername: key_webroot: ''
	server {
		listen 80;
		listen [::]:80;
		server_name ${servername};
		location /.well-known/acme-challenge {
			default_type text/plain;
			alias ${key_webroot}/.well-known/acme-challenge;
		}
	}
'';
makeServerBlock = servername: {key_root, key_webroot, contents, ...}: ''
	server {
		listen 80;
		listen [::]:80;
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
		listen       [::]:443;
		server_name  ${servername};
		location /.well-known/acme-challenge {
			default_type text/plain;
			alias ${key_webroot}/.well-known/acme-challenge;
		}
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
        	default = {};
        	example = {"mail.domain.com" = "/var/lib/acme/mail.domain.com";};
        	description = "Other domains to host challenges for";
        };
    };
    config = mkIf cfg.enable {
	  services.nginx = {
	    enable = true;
	    recommendedTlsSettings = true;
	    recommendedGzipSettings = true;
	    recommendedProxySettings = true;
	    recommendedOptimisation = true;
	    serverTokens = false;
	    sslDhparam = "/etc/nginx/dhparam.pem";
	    virtualHosts = {
	    	"\"\"" = {
	    		forceSSL = true;
	    		locations."/" = {
	    			index = "index.html index.htm";
	    			root = "${pkgs.nginx}/html";
	    		};
	    		sslCertificate = "${cfg.no_vhost_keydir}/fullchain.pem";
	    		sslCertificateKey = "${cfg.no_vhost_keydir}/key.pem";
	    		default = true;
	    	};
	    };

	    appendHttpConfig = ''

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
	      # self-sign certs in case an invalid vhost is looked up
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
