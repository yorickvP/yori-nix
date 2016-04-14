# https://uggz.tk/gebner/nixos-config/src/master/pkgs/gogs.nix
{ nixpkgs ? import <nixpkgs> {} }: with nixpkgs;
stdenv.mkDerivation rec {
  name = "gogs-${version}";
  version = "0.9.0";
  src = fetchzip {
    url = "https://dl.gogs.io/gogs_v${version}_linux_amd64.tar.gz";
    sha256 = "1qyy0hi8hvz2k4p9251mx8xv9z08jwijfzl0rn0drm6sq34a7wg9";
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
