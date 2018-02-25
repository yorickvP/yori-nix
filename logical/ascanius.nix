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
    ];

  # no, not that Ascanius.
  networking.hostName = secrets.hostnames.ascanius;

  nixpkgs.config = {
    packageOverrides = pkgs : {
      bluez = pkgs.bluez5;
      # https://github.com/NixOS/nixpkgs/issues/22099
      trustedGrub = pkgs.grub2.overrideDerivation (attr: rec {
        version = "2.x-20170910";
        name = "trustedGRUB2-${version}";
        buildInputs = attr.buildInputs ++ (with pkgs;[autoconf automake]);
        prePatch = ''
          rm -rf po
          tar Jxf ${pkgs.grub2.src} grub-2.02/po
          cp -r grub-2.02/po po
          ./autogen.sh
        '';
        src = pkgs.fetchFromGitHub {
          repo = "TrustedGRUB2";
          owner = "Rohde-Schwarz-Cybersecurity";
          rev = "e656aaabd3bc5abda6c62c8967ebfd0c53ef179b";
          sha256 = "08lq4prqhn923i8a7q79s4lsfnqgk4jd255xzk1wy12vg45dwlsc";
        };
      });
    };
  };


  services.tor.hiddenServices.ssh.map = [{ port = 22; }];
  nix.gc.automatic = pkgs.lib.mkOverride 30 false;
}
