{ config, lib, pkgs, ... }:
# check if it's working:
# nix-shell -p nvme-cli --command "sudo nvme get-feature -f 0x0c -H /dev/nvme0" | grep Enable
{	boot = rec {
		# gotta go faster
		kernelPackages = pkgs.linuxPackages_latest // {
			kernel = pkgs.linuxPackages_latest.kernel.overrideDerivation (attr: {
				enableParallelBuilding = true;
			});
		};

		kernelPatches = let
				kver = kernelPackages.kernel.version;
				kernel_newer_4_9 = builtins.compareVersions kver "4.9" > -1;
				# https://github.com/damige/linux-nvme/
				linux-nvme = pkgs.fetchFromGitHub {
					owner = "damige";
					repo = "linux-nvme";
					rev = "49204bb12ca0797e17d70f21bb947a99eaeebbfa";
					sha256 = "1bybrr0j7n81vhf3g36cm8sfmax0kp0b3xndlbcr5im9zrlkvwkj";
				};
			in map (name: { patch = "${linux-nvme}/src/${kver}/${name}.patch"; inherit name; })
			(if kernel_newer_4_9
				then ["APST" "pm_qos1" "pm_qos2" "pm_qos3" "nvme"]
				else ["nvmepatch1-V4" "nvmepatch2-V4" "nvmepatch3-V4"]);
	};
}
