{ config, lib, pkgs, ... }:

let
  acmeKeyDir = "${config.security.acme.directory}/${cfg.vhost}";
  communityModules = [ "mam" "carbons" "smacks" ];
  cfg = config.services.yorick.xmpp;
in
{
  options.services.yorick.xmpp = with lib; {
    enable = mkEnableOption "xmpp";
    vhost = mkOption { type = types.string; };
    admins = mkOption { type = types.listOf types.string; };
  };
  config = lib.mkIf cfg.enable {
    # XMPP
    services.prosody = let
  in {
      enable = true;
      
      allowRegistration = false;
      extraModules = [ "private" "vcard" "privacy" "compression" "muc" "pep" "adhoc" "lastactivity" "admin_adhoc" "blocklist"] ++ communityModules;
      virtualHosts.default = {
        enabled = true;
        domain = cfg.vhost;
        ssl = {
          key = "/var/lib/prosody/keys/key.pem";
          cert = "/var/lib/prosody/keys/fullchain.pem";
        };
      };
      # TODO: Component "chat.yori.cc" "muc" # also proxy65 and pubsub?
      extraConfig = ''
        use_libevent = true
        s2s_require_encryption = true
        c2s_require_encryption = true
        archive_expires_after = "never"
        storage = {
          archive2 = "sql";
        }
      '';
      inherit (cfg) admins;
      package = pkgs.prosody.override {
        withZlib = true; withDBI = true;
        withCommunityModules = communityModules;
      };
    };
    systemd.services.prosody.serviceConfig.PermissionsStartOnly = true;
    systemd.services.prosody.preStart = ''
      mkdir -m 0700 -p /var/lib/prosody/keys
      cp ${acmeKeyDir}/key.pem ${acmeKeyDir}/fullchain.pem /var/lib/prosody/keys
      chown -R prosody:prosody /var/lib/prosody
    '';
    networking.firewall.allowedTCPPorts = [5222 5269];
    security.acme.certs.${cfg.vhost}.postRun = ''
      systemctl restart prosody.service
    '';
  };
}
