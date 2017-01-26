{ pkgs, config, lib, ... }:


let
  cfg = config.services.muflax-blog;
  muflax-source = pkgs.fetchFromGitHub {
    rev = "e5ce7ae4296c6605a7e886c153d569fc38318096";
    owner = "fmap";
    repo = "muflax65ngodyewp.onion";
    sha256 = "10n5km8mr7vjqlyb46drfhwzlrwranqaxpqc53a2hk9pqqckm8cx";
  };
  blog = lib.overrideDerivation (pkgs.callPackage "${muflax-source}/maintenance" {}) (default: {
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
    services.tor.hiddenServices = [{
      name = "muflax-blog";
      remote_port = 80;
      inherit (cfg.web-server) port;
      inherit (cfg.hidden-service) hostname private_key;
    }];
  };
}