{ config, pkgs, ... }:

{
  imports =
    [ <yori-nix/physical/hp8570w.nix>
      <yori-nix/roles/workstation.nix>
    ];

  system.stateVersion = "17.09";

}
