{ config, pkgs, lib, ... }:

{
	# todo: the prestart service copies to the wrong dir
	services.asterisk = {
		enable = true;
		#extraArguments = ["-vvvddd"];
		confFiles."logger.conf" = ''
		  [general]
		  [logfiles]
		  syslog.local0 => notice,warning,error
		  console => debug,notice,warning,error,verbose,dtmf,fax
		'';
		confFiles."extensions.conf" = ''
			[from-sim]
			  exten => _X.,1,Verbose(Call from Limesco SIM [''${CALLERID(num)}] to [''${EXTEN}])
			  same  =>     n,Dial(SIP/speakup01/''${EXTEN})

			[from-speakup]
			; Vervang ... door de rest van je DIY-nummer:
			  exten => 31626972516,1,Verbose(Call from SpeakUp [''${CALLERID(num)}] to [''${EXTEN}])
			  same  =>        n,Dial(SIP/limesco/''${EXTEN})
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
