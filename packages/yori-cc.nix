{ stdenv, callPackage }:

let gogitget = callPackage ./gogitget.nix {}; in

stdenv.mkDerivation {
  name = "yori-cc-1.3.5";
  
  src = gogitget {
    "url" = "git@git.yori.cc:yorick/yori-cc.git";
    "rev" = "f049e4330dfb64bbbaf700897269c003fce8b5c4";
    "sha256" = "1x8knlsp7cx52sr15gr0yhj1vl8ncznrqn4nvaycgwmhr1kysffr";
  };
  
  buildInputs = [ ];

  installPhase = ''
    mkdir -p "$out/web"
    cp -ra * "$out/web"
  '';

  meta = {
    description = "Yori-cc website";
    homepage = https://yorickvanpelt.nl;
    maintainers = [ "Yorick" ];
  };
}
