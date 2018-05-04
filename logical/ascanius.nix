{ config, pkgs, ... }:

{
  imports =
    [ <yori-nix/physical/hp8570w.nix>
      <yori-nix/roles/workstation.nix>
    ];

  system.stateVersion = "17.09";


  nix = {
    binaryCaches = [
      "https://cache.nixos.org"
    ];
    trustedBinaryCaches = config.nix.binaryCaches ++ [
      "https://builder.serokell.io"
    ];
    binaryCachePublicKeys = [
      "serokell:ic/49yTkeFIk4EBX1CZ/Wlt5fQfV7yCifaJyoM+S3Ss="
    ];
  };
}
