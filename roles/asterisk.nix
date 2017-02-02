{ config, pkgs, lib, ... }:

{
	# todo: the prestart service copies to the wrong dir
	services.asterisk = {
		enable = true;
		#extraArguments = ["-vvvddd"];
		confFiles."asterisk.conf" = ''
	[directories]
	astetcdir => /etc/asterisk/
	astmoddir => ${pkgs.asterisk}/lib/asterisk/modules
	astvarlibdir => /var/lib/asterisk
	astdbdir => /var/lib/asterisk
	astkeydir => /var/lib/asterisk
	astdatadir => /var/lib/asterisk
	astagidir => /var/lib/asterisk/agi-bin
	astspooldir => /var/spool/asterisk
	astrundir => /var/run/asterisk
	astlogdir => /var/log/asterisk
	astsbindir => ${pkgs.asterisk}/sbin
		'';
	};
	environment.etc = {
	    # Loading all modules by default is considered sensible by the authors of
	    # "Asterisk: The Definitive Guide". Secure sites will likely want to
		# specify their own "modules.conf" in the confFiles option.
		"asterisk/modules.conf".text = ''
		  [modules]
		  autoload=yes
		'';

		# Use syslog for logging so logs can be viewed with journalctl
		"asterisk/logger.conf".text = ''
		  [general]
		  [logfiles]
		  syslog.local0 => notice,warning,error
		  console => debug,notice,warning,error,verbose,dtmf,fax
		'';
	};
	environment.systemPackages = with pkgs; [
	  asterisk
	];
	#networking.firewall.allowedUDPPorts = [5060];
	#networking.firewall.allowedTCPPorts = [5060];
	networking.firewall.extraCommands = ''
	    iptables -A nixos-fw -p udp -s 193.169.138.0/23 -j nixos-fw-accept
	    iptables -A nixos-fw -p udp -s 91.232.130.0/24 -j nixos-fw-accept
	    iptables -A nixos-fw -p udp -s 81.205.5.19 -j nixos-fw-accept
	    iptables -A nixos-fw -p tcp -s 193.169.138.0/23 -j nixos-fw-accept
	    iptables -A nixos-fw -p tcp -s 91.232.130.0/24 -j nixos-fw-accept
	    iptables -A nixos-fw -p tcp -s 81.205.5.19 -j nixos-fw-accept
	'';
	# nixpkgs.config = {
	#   packageOverrides = pkgs : {
	# 	asterisk = pkgs.asterisk.overrideDerivation (attrs: rec {
	#       version = "13.11.2";
	#       broken = false;

	#       src = pkgs.fetchurl {
	#           url = "http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${version}.tar.gz";
	#           sha256 = "0fjski1cpbxap1kcjg6sgd6c8qpxn8lb1sszpg6iz88vn4dh19vf";
	#       };
	#     });
	#   };
	# };
}
