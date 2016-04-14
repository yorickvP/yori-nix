{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config."nixos-in-place";
in
{
  imports = [ ];
  options."nixos-in-place" = {
    enable = mkEnableOption "enable nixos-in-place FS";
    rootfs = mkOption {
      type = types.string;
      description = "device name for root fs";
    };
    swapfs = mkOption {
      type = types.string;
      description = "device name for root fs";
    };
  };
  config = mkIf cfg.enable {
    boot = {
  	  kernelModules = [ ];
  	  extraModulePackages = [ ];
  	  kernelParams = ["root=${cfg.rootfs}" "boot.shell_on_fail"];
      loader.grub  = {
        enable = true;
        storePath = "/nixos/nix/store";
      };
      initrd = {
        supportedFilesystems = [ "ext4" ];
        postDeviceCommands = ''
          mkdir -p /mnt-root/old-root ;
          mount -t ext4 ${cfg.rootfs} /mnt-root/old-root ;
        '';
      };
    };

    fileSystems = {
      "/" = {
        device = "/old-root/nixos";
        fsType = "none";
        options = [ "bind" ];
      };
      "/old-root" = {
        device = cfg.rootfs;
        fsType = "ext4";
      };
    };
    swapDevices = [ { device = cfg.swapfs; } ];
  };
}
