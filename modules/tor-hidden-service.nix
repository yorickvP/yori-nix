{ config, lib, ... }:

with lib;

let
  service-keys = config.services.tor.service-keys;
  torDir = "/var/lib/tor";
in {
  options.services.tor.service-keys = mkOption {
    default = {};
    type = with types; loaOf string;
  };

  config = mkIf (service-keys != {}) {
    systemd.services."install-tor-hidden-service-keys" = {
      wantedBy = ["tor.service"];
      serviceConfig.Type = "oneshot";
      serviceConfig.User = "root";
      serviceConfig.Group = "keys";
      # TODO: update on change?
      # TODO: better ways to get the keys on the server
      script = concatStringsSep "\n" (mapAttrsToList (name: keypath: ''
        if ! [[ -e ${torDir}/onion/${name}/private_key ]]; then
          mkdir -p ${torDir}/onion/${name}/
          cp ${keypath} ${torDir}/onion/${name}/private_key
          chmod -R 700 ${torDir}/onion/${name}
          chown -R tor ${torDir}/onion/${name}
        fi
      '') service-keys);
    };
  };
}
