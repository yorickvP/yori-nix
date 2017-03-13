{ config, lib, pkgs, ... }:
# check if it's working:
# nix-shell -p nvme-cli --command "sudo nvme get-feature -f 0x0c -H /dev/nvme0" | grep Enable
let
cfg = config.linux_nvme;
inherit (lib) mkIf mkOption mkEnableOption;
in
{
	options.linux_nvme = {
	    basekpkgs = mkOption { default = pkgs.linuxPackages_latest; };
	    gofaster = mkEnableOption "enable parallel building on kernel";
	    nvmepatch = mkEnableOption "enable nvme patch";
	};
	config.boot = rec {
		# gotta go faster
		kernelPackages = mkIf cfg.gofaster (cfg.basekpkgs // {
			kernel = cfg.basekpkgs.kernel.overrideDerivation (attr: {
				enableParallelBuilding = true;
			});
		});

		kernelPatches = mkIf cfg.nvmepatch (let
				newerThan = v: builtins.compareVersions config.boot.kernelPackages.kernel.version v > -1;
				# https://github.com/damige/linux-nvme/
				linux-nvme = pkgs.fetchFromGitHub {
					owner = "damige";
					repo = "linux-nvme";
					rev = "4e9b1de7ad5386f6c8c208d81005a77d79460d26";
					sha256 = "151pnv1gjrcmlvw8bx0ndpvn254jjy394h8yr3sgh2gqbc5i1aqp";
				};
				mkpatches = dir: map (name: { patch = "${linux-nvme}/patches/${dir}/${name}.patch"; inherit name; });
			in
			if newerThan "4.11" then [] else
			if newerThan "4.10" then (mkpatches "4.10.x" ["APST"]) else
			if newerThan "4.9" then (mkpatches "4.9.x" ["APST" "pm_qos1" "pm_qos2" "pm_qos3" "nvme"]) else
			if newerThan "4.8" then (mkpatches "4.8.x" ["nvmepatch1-V4" "nvmepatch2-V4" "nvmepatch3-V4"]) else
			throw "unknown kernel version");
	};
}
