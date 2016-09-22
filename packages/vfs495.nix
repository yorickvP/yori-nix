{ pkgs ? import <nixpkgs> {} }: with pkgs;
let
# this is ugly but it works
openssl_0_9_8 = runCommand "openssl_0_9_8" {} ''
  mkdir -p $out/lib/
  ln -s ${openssl_1_0_1.out}/lib/libcrypto.so $out/lib/libcrypto.so.0.9.8
  ln -s ${openssl_1_0_1.out}/lib/libssl.so $out/lib/libssl.so.0.9.8
'';
in
stdenv.mkDerivation rec {
  version = "4.5-118.00";
  name = "vfs495-${version}";

  src = fetchurl {
    url = "https://dl.dropboxusercontent.com/u/71679/Validity-Sensor-Setup-${version}.x86_64.rpm";
    sha256 = "1hd03bv14zr639l0wnwcc0bggjsfpnq57fjz3vqym19xqn9ks001";
  };
  nativeBuildInputs = [ patchelf ];
  buildInputs = [libusb libusb1 openssl_0_9_8];
  unpackCmd = ''
    (mkdir -p "${name}" && cd "${name}" &&
      ${rpmextract}/bin/rpmextract "$curSrc")'';
  installPhase = ''
    mkdir -p $out
    cp -R etc/ usr/ $out/
    patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
         --set-rpath "${lib.makeLibraryPath buildInputs}" \
        $out/usr/bin/vcsFPService
    patchelf --set-rpath "${lib.makeLibraryPath buildInputs}" \
        $out/usr/lib/libvfsFprintWrapper.so
  '';
  meta = with stdenv.lib; {
      description = "Userspace driver for VFS495 fingerprint readers";
      license = licenses.unfreeRedistributable;
      #maintainers = with maintainers; [ yorickvp ];
      platforms = platforms.linux;
  };
}
