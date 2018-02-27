{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ../physical/xps9360.nix
      ../roles/common.nix
      ../roles/workstation.nix
    ];

  networking.hostName = "jarvis"; # Define your hostname.


  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "17.09";
  #networking.enableIPv6 = lib.mkOverride 30 true;


  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --dpi 192
  '';
  virtualisation.virtualbox.host.enable = pkgs.lib.mkOverride 30 false;
}
