{ cur_pkgs, config, lib, ... }:


let
  cfg = config.services.muflax-blog;
  muflax-source = builtins.fetchGit {
    rev = "e5ce7ae4296c6605a7e886c153d569fc38318096";
    ref = "HEAD";
    url = "https://github.com/fmap/muflax65ngodyewp.onion.git";
};
nixpkgs = import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs-channels/archive/78e9665b48ff45d3e29f45b3ebeb6fc6c6e19922.tar.gz";
  sha256 = "09f50jaijvry9lrnx891qmcf92yb8qs64n1cvy0db2yjrmxsxyw8";
}) { system = builtins.currentSystem; };
  blog = lib.overrideDerivation (nixpkgs.callPackage "${muflax-source}/maintenance" {}) (default: {
    buildPhase = default.buildPhase + "\n" + ''
      grep -lr '[^@]muflax.com' out | xargs -r sed -i 's/\([^@]\)muflax.com/\1${cfg.hidden-service.hostname}/g'
    '';
  });
in with lib; {
  options.services.muflax-blog = {
    enable = mkOption { type = types.bool; default = false; };
    web-server = {
      port = mkOption { type = types.int; };
    };
    hidden-service = {
      hostname    = mkOption { type = types.str; };
      private_key = mkOption { type = types.str; };
    };
  };
  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      appendHttpConfig = ''
        server {
          index index.html;
          port_in_redirect off;
          listen 127.0.0.1:${toString cfg.web-server.port};
          server_name ${cfg.hidden-service.hostname};
          root ${blog}/muflax;
        }
      '' + concatStringsSep "\n" (map (site: ''
        server {
          index index.html;
          port_in_redirect off;
          listen 127.0.0.1:${toString cfg.web-server.port};
          server_name ${site}.${cfg.hidden-service.hostname};
          root ${blog}/${site};
        }
      '') ["daily" "gospel" "blog"]);
    };
    services.tor.hiddenServices.muflax-blog.map = [{
      port = 80; toPort = cfg.web-server.port; }];
    services.tor.service-keys.muflax-blog = cfg.hidden-service.private_key;
  };
}
