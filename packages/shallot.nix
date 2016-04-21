with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "shallot-0.0.3-alpha";

  src = fetchFromGitHub {
    rev = "831de01b13b309933d32efe8388444ef6a831cfb";
    owner = "katmagic";
    repo = "Shallot";
    sha256 = "0zlgl13vmv6zj1jk5cfjqg66n3qq9yp2202llpgvfl16rzxrlv5r";
  };

  buildInputs = [openssl];

  buildPhase = ''
    ./configure
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv shallot $out/bin
  '';
}