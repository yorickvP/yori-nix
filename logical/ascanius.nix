{ config, pkgs, ... }:

let secrets = import <secrets>;
in
{
  imports =
    [ ../physical/hp8570w.nix
      ../roles/common.nix
      ../roles/workstation.nix
    ];

  system.stateVersion = "17.09";
  # no, not that Ascanius.
  networking.hostName = secrets.hostnames.ascanius;
  services.tor.hiddenServices.ssh.map = [
    { port = 22; }
  ];
  services.tor.service-keys.ssh = "/run/keys/torkeys/ssh.ascanius.key";

}
