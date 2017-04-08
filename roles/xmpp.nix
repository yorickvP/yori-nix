{ config, lib, pkgs, ... }:

let
  luadbi = pkgs.callPackage ../packages/luadbi.nix {};
  acmeKeyDir = "${config.security.acme.directory}/yori.cc";
in
{
  # XMPP
  services.prosody = let
    # TODO: this should be in nixpkgs
    prosodyModules = pkgs.fetchhg {
      name = "prosody-modules-22042016";
      rev = "e0b8b8a50013";
      sha256 = "06qd46bmwjpzrygih91fv7z7g8z60kn0qyr7cf06a57a28117wdy";
      url = "https://hg.prosody.im/prosody-modules/";
    };
  in {
    enable = true;

    allowRegistration = false;
    extraModules = [ "private" "vcard" "privacy" "compression" "muc" "pep" "adhoc" "lastactivity" "admin_adhoc" "blocklist" "mam" "carbons" "smacks"];
    virtualHosts.yoricc = {
      enabled = true;
      domain = "yori.cc";
      ssl = {
        key = "/var/lib/prosody/keys/key.pem";
        cert = "/var/lib/prosody/keys/fullchain.pem";
      };
    };
    # TODO: Component "chat.yori.cc" "muc" # also proxy65 and pubsub?
    extraConfig = ''
      plugin_paths = { "${prosodyModules}" }
      use_libevent = true
      s2s_require_encryption = true
      c2s_require_encryption = true
      archive_expires_after = "never"
      storage = {
        archive2 = "sql";
      }
    '';

    admins = [ "yorick@yori.cc"];
  };
  nixpkgs.config.packageOverrides = pkgs:
    # FIXME: ugly hacks!
    { prosody = pkgs.prosody.override { withZlib = true; luazlib = luadbi; };
    };
  systemd.services.prosody.serviceConfig.PermissionsStartOnly = true;
  systemd.services.prosody.preStart = ''
      mkdir -m 0700 -p /var/lib/prosody/keys
      cp ${acmeKeyDir}/key.pem ${acmeKeyDir}/fullchain.pem /var/lib/prosody/keys
      chown -R prosody:prosody /var/lib/prosody
  '';
  networking.firewall.allowedTCPPorts = [5222 5269];

}
