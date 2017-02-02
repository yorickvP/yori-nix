{ pkgs ? import <nixpkgs> {} }:
let
  inherit (pkgs) stdenv makeWrapper lib;
  powerswpackages = with pkgs; [ hdparm iw gawk kmod ];
  powerswpath = lib.makeBinPath powerswpackages;
in
stdenv.mkDerivation rec {
  name = "powerdown";
  src = ./.;
  buildPhase = "true";
  nativeBuildInputs = [ makeWrapper ];
  makeFlags = "DESTDIR=$(out)";
  postInstall = ''
  	wrapProgram $out/bin/powerup --prefix PATH : ${powerswpath}
  	wrapProgram $out/bin/powerdown --prefix PATH : ${powerswpath}
    wrapProgram $out/bin/powernow --prefix PATH : ${powerswpath}
  	wrapProgram $out/bin/powerswitch --prefix PATH : ${powerswpath}
  '';
}
