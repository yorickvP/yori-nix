# https://uggz.tk/gebner/nixos-config/src/master/pkgs/gogs.nix
{ nixpkgs ? import <nixpkgs> {} }: with nixpkgs;
stdenv.mkDerivation rec {
  name = "gogs-${version}";
  version = "0.9.113";
  src = fetchzip {
    url = "https://dl.gogs.io/gogs_v${version}_linux_amd64.tar.gz";
    sha256 = "0gwpshzch1b0s810pd5cpiad1skvnjhsd6kx9gmlbw2whdp2jf2r";
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
