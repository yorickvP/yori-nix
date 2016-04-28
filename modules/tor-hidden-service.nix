{ config, lib, ... }:

with lib;

let
  hiddenServices = config.services.tor.hiddenServices;
in {
  options.services.tor = { 
    hiddenServices = mkOption { default = []; };
  };

  config = mkIf (hiddenServices != []) {
    assertions = map (hiddenService: {
      assertion = hasAttr "name" hiddenService && hasAttr "port" hiddenService;
      message   = "all hidden services should define a name and a port..";
    }) hiddenServices;

    services.tor.enable = true;

    services.tor.extraConfig = concatStringsSep "\n" (map (hiddenService: ''
      HiddenServiceDir /var/lib/tor/${hiddenService.name}
      HiddenServicePort ${toString (if hasAttr "remote_port" hiddenService then hiddenService.remote_port else hiddenService.port)} 127.0.0.1:${toString hiddenService.port}
    '') hiddenServices);

    systemd.services."install-tor-hidden-service-keys" = {
      wantedBy = ["tor.service"];
      serviceConfig.Type = "oneshot";
      serviceConfig.User = "tor";
      serviceConfig.Group = "keys";
      # TODO: update on change?
      # TODO: better ways to get the keys on the server
      script = concatStringsSep "\n" (map (hiddenService: if (hasAttr "private_key" hiddenService && hasAttr "hostname" hiddenService) then ''
        if ! [[ -e /var/lib/tor/${hiddenService.name}/private_key ]]; then
          mkdir -p /var/lib/tor/${hiddenService.name}/
          cp ${hiddenService.private_key} /var/lib/tor/${hiddenService.name}/private_key
          echo ${hiddenService.hostname} > /var/lib/tor/${hiddenService.name}/hostname
          chmod -R 700 /var/lib/tor/${hiddenService.name};
        fi
      '' else "true") hiddenServices);
    };
  };
}
