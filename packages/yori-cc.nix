with import <nixpkgs> {};

let gogitget = callPackage ./gogitget.nix {}; in

stdenv.mkDerivation {
  name = "yori-cc-1.1";
  
  src = gogitget {
    url = "git@git.yori.cc:yorick/yori-cc.git";
    rev = "b5ca927b1c725b4a674a73f546d010be739472ff";
    sha256 = "3e4c25358d96b6fc3819b7b74e33c84de508c930910399784af2bd3a82c1f3bd";
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
