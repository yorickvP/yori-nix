# https://uggz.tk/gebner/nixos-config/src/master/pkgs/gogs.nix
{ nixpkgs ? import <nixpkgs> {} }: with nixpkgs;
stdenv.mkDerivation rec {
  name = "gogs-${version}";
  version = "0.8.10";
  src = fetchzip {
    url = "https://dl.gogs.io/gogs_v${version}_linux_amd64.tar.gz";
    sha256 = "0c0abr0jinyvwhw84901ga80x6q13a0q8yrs6k5i8jawhpwvfl67";
  };
  buildPhase = ''
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath ${pam}/lib \
      gogs
  '';
  installPhase = ''
    cp -ra ./ $out/
  '';
}
