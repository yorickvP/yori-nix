with import <nixpkgs> {};

let gogitget = callPackage ./gogitget.nix {}; in

stdenv.mkDerivation {
  name = "yori-cc-1.0";
  
  src = gogitget {
    url = "git@git.yori.cc:yorick/yori-cc.git";
    rev = "965d05d8258821ece8d7421027acf9541437ff26";
    sha256 = "0dcdc2b00e4ba3f9fb2afe5a8b41afd5eb2b03f308dfa48827722f23c489f0d7";
  };
  
  buildInputs = [ ];

  installPhase = ''
    mkdir -p "$out/web"
    cp -ra * "$out/web"
  '';

  meta = {
    description = "Yori-cc website";
    homepage = http://yori.cc;
    maintainers = [ "Yorick" ];
  };
}
