# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ../physical/xps9360.nix
      ../roles/common.nix
      ../roles/workstation.nix
    ];

  networking.hostName = "jarvis"; # Define your hostname.


  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "17.03";


  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --dpi 192
  '';
  nix.gc.automatic = pkgs.lib.mkOverride 30 false;

}
