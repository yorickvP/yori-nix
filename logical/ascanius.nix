# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let secrets = import <secrets>;
in
{
  imports =
    [ ../physical/hp8570w.nix
      ../roles/common.nix
      ../roles/workstation.nix
      ../modules/tor-hidden-service.nix
    ];

  # no, not that Ascanius.
  networking.hostName = secrets.hostnames.ascanius;

  # GOTTA GO FASTER
  # this pulls in systemd-udevd-settle, which slows down boot
  systemd.services.scsi-link-pm.enable = false;

  nixpkgs.config = {
    packageOverrides = pkgs : {
      bluez = pkgs.bluez5;
      # https://github.com/NixOS/nixpkgs/issues/22099
      trustedGrub = pkgs.trustedGrub.overrideDerivation (attr: {NIX_CFLAGS_COMPILE = "-Wno-error";});
    };
  };


  services.tor.hiddenServices = [
    { name = "ssh";
      port = 22;
      hostname = secrets.tor_hostnames."ssh.ascanius";
      private_key = "/run/keys/torkeys/ssh.ascanius.key"; }
  ];
  nix.gc.automatic = pkgs.lib.mkOverride 30 false;
}
