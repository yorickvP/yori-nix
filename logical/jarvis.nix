{ config, pkgs, lib, ... }:

{
  imports =
    [ <yori-nix/physical/xps9360.nix>
      <yori-nix/roles/workstation.nix>
    ];


  system.stateVersion = "17.09";
  #networking.enableIPv6 = lib.mkOverride 30 true;


  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --dpi 192
  '';
  virtualisation.virtualbox.host.enable = pkgs.lib.mkOverride 30 false;
}
