with import <nixpkgs> {};

let gogitget = callPackage ./gogitget.nix {}; in

stdenv.mkDerivation {
  name = "yori-cc-1.3";
  
  src = gogitget {
    "url" = "git@git.yori.cc:yorick/yori-cc.git";
    "rev" = "db207b9fd74a1036d2272c38dcbb6de504cf590a";
    "sha256" = "1rqsv7pdij15f6nxxwggw58q12ggl6g7gjjq73sbdz1v9x78xbzp";
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
