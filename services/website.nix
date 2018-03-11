{ config, lib, pkgs, ... }:

let
  yoricc = pkgs.callPackage ../packages/yori-cc.nix {};
  cfg = config.services.yorick.website;
in
  with lib;
{
  options.services.yorick = {
    website = {
      enable = mkEnableOption "yoricc website";
      vhost = mkOption { type = types.string; };
      pkg = mkOption { type = types.package; default = yoricc; };
    };
    redirect = mkOption { type = types.loaOf types.string; default = []; };
  };
  config.services.nginx.virtualHosts = with cfg; mkIf enable {
    ${vhost} = {
      enableACME = true;
      forceSSL = true;
      locations."/".root = "${pkg}/web";
    };
  };

}
