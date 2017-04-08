# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

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
  system.stateVersion = "17.03";
  networking.enableIPv6 = lib.mkOverride 30 true;


  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --dpi 192
  '';
  nix.gc.automatic = pkgs.lib.mkOverride 30 false;
  # nix.trustedBinaryCaches = [http://192.168.1.27:5000];
  # nix.binaryCachePublicKeys = [
  #   "hydra.example.org-1:NbZfmBIhIevVM5OZ81TbwruSC9etkIrdi1mR6AAdm98="
  # ];
  virtualisation.virtualbox.host.enable = pkgs.lib.mkOverride 30 false;
}
