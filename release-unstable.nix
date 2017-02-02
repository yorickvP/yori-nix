let
	nixos = import <nixpkgs/nixos>;
	nixpkgs = import <nixpkgs> {};
	nixosFor = path: nixos {configuration = import path;};
in
{
	ascanius = nixpkgs.lib.hydraJob (nixosFor ./logical/ascanius.nix).system;
	jarvis = nixpkgs.lib.hydraJob (nixosFor ./logical/jarvis.nix).system;
}
