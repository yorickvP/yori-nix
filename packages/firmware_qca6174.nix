{ stdenv, fetchurl  }:
stdenv.mkDerivation rec {
  target = "QCA6174";
  branch = "4.4.1.c1";
  version = "${branch}-00042";
  name = "${target}-firmware-${version}";
  src = fetchurl {
    url = "https://github.com/kvalo/ath10k-firmware/raw/master/${target}/hw3.0/${branch}/firmware-6.bin_RM.${version}-QCARMSWP-1";
    sha256 = "01vvz3qhqw5l3yilcqgk1spk4y9k4qy7na7a57cbl037r231szdh";
  };
  buildCommand = ''
    install -D $src $out/lib/firmware/ath10k/${target}/hw3.0/firmware-6.bin
  '';
}
