{ config, lib, pkgs, ... }:
let cfg = config.hardware.yorick; in
with lib;
{
  options.hardware.yorick = {
    cpu = mkOption {
      type = types.nullOr (types.enum ["intel" "virtual"]);
    };
    gpu = mkOption {
      type = types.nullOr (types.enum ["intel" "nvidia"]);
      default = null;
    };
    laptop = mkEnableOption "laptop settings";
  };
  config = mkMerge [
    (mkIf (cfg.gpu == "intel") {
      # https://wiki.archlinux.org/index.php/Dell_XPS_13_(9360)#Module-based_Powersaving_Options
      boot.kernelParams = ["i915.enable_fbc=1" "i915.enable_guc_loading=1" "i915.enable_guc_submission=1" "i915.enable_huc=1" "i915.enable_psr=2"];
      # now we wait until enable_psr=1 is fixed
      services.xserver.videoDrivers = ["modesetting"];
      hardware.opengl.extraPackages = [ pkgs.vaapiIntel ];
    })
    (mkIf (cfg.gpu == "nvidia") {
      boot.kernelModules = ["nvidiabl"];
      services.xserver.videoDrivers = ["nvidia"];
      boot.extraModulePackages = [config.boot.kernelPackages.nvidiabl];
    })
    (mkIf (cfg.cpu == "intel") {
      hardware.cpu.intel.updateMicrocode = true;
      boot.kernelModules = ["kvm-intel"];
    })
    (mkIf (cfg.laptop) {
      services.xserver.libinput.enable = true;
      
      networking.wireless.enable = true;
      hardware.bluetooth.enable = true;
      # gotta go faster
      networking.dhcpcd.extraConfig = ''
        noarp
      '';
      services.thermald.enable = true;
    })
  ];
}
