with import <nixpkgs> {};

let gogitget = callPackage ./gogitget.nix {}; in

stdenv.mkDerivation {
  name = "yori-cc-1.2";
  
  src = gogitget {
    "url" = "git@git.yori.cc:yorick/yori-cc.git";
    "rev" = "6e73c0152a9e5b0109e714fb57ca0d401cbf27a1";
    "sha256" ="1zmwl5rlbd80ml0qng1n0xh0mkps1nsmngnvcqjbb3247692lvpj";
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
