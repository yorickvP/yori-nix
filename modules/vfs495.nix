{ pkgs, config, lib, ... }:

let
vfs495 = pkgs.callPackage ../packages/vfs495.nix { };
cfg = config.services.vfs495;
in
{
	options.services.vfs495 = with lib; {
	  enable = mkOption { type = types.bool; default = false; };
	};
  	config = lib.mkIf cfg.enable {
		nixpkgs.config = {
		  packageOverrides = pkgs : {
		    libfprint = pkgs.libfprint.overrideDerivation (attrs: {
		      patches = [(pkgs.fetchurl {
		          url = "http://ix.io/1eh0";
		          sha256 = "1h55gc07piidixxm5h37p0514h67q0z1q9ygapyl89in3csd5n94";
		        })];
		      buildInputs = [pkgs.autoreconfHook] ++ attrs.buildInputs;
		    });
		  };
		};
		services.fprintd.enable = true;
		systemd.services.fprintd = {
			path = [pkgs.procps];
			environment.LD_LIBRARY_PATH = "${vfs495}/usr/lib";
		};
		systemd.services.vfs495 = {
			serviceConfig = {
				Type = "forking";
				ExecStartPre = "rm -f /tmp/vcsSemKey_*";
				ExecStart = "${vfs495}/usr/bin/vcsFPService";
			};
			wantedBy = [ "multi-user.target" ];
			before = ["fprintd.service"];
		};
		# TODO: send SIGUSR1 on suspend and SIGUSR2 on resume
	};
}
