# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports = [
    <yori-nix/physical/kassala.nix>
    <yori-nix/roles/server.nix>
    ../modules/muflax-blog.nix
  ];

  networking.enableIPv6 = lib.mkOverride 30 true;

  system.stateVersion = "16.03";
  
  services.nginx.enable = true;
  services.yorick = {
    website = { enable = true; vhost = "yorickvanpelt.nl"; };
    mail = {
      enable = true;
      mainUser = "yorick";
      users.yorick = {
        password = (import <yori-nix/secrets.nix>).yorick_mailPassword;
        domains = ["yori.cc" "yorickvanpelt.nl"];
      };
    };
    xmpp = {
      enable = false;
      vhost = "yori.cc";
      admins = [ "yorick@yori.cc" ];
    };
  };
  services.nginx.virtualHosts."yori.cc" = {
    enableACME = true;
    forceSSL = true;
    globalRedirect = "yorickvanpelt.nl";
  };




  services.muflax-blog = {
    enable = true;
    web-server = {
      port = 9001;
    };
    hidden-service = {
      hostname = "muflax65ngodyewp.onion";
      private_key = "/root/keys/http.muflax.key";
    };
  };
  users.extraUsers.git = {
    createHome = true;
    home = config.services.gitea.stateDir; extraGroups = [ "git" ]; useDefaultShell = true;};
  services.gitea = {
    enable = true;
    user = "git";
    database.user = "root";
    database.name = "gogs";
    #dump.enable = true; TODO: backups
    domain = "git.yori.cc";
    rootUrl = "https://git.yori.cc/";
    httpAddress = "localhost";
    cookieSecure = true;
    extraConfig = ''
      [service]
      REGISTER_EMAIL_CONFIRM = false
      ENABLE_NOTIFY_MAIL = false
      DISABLE_REGISTRATION = true
      REQUIRE_SIGNIN_VIEW = false
      [picture]
      DISABLE_GRAVATAR = false
      [mailer]
      ENABLED = false
      AVATAR_UPLOAD_PATH = ${config.services.gitea.stateDir}/data/avatars
    '';
  };
  services.nginx.virtualHosts."git.yori.cc" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.gitea.httpPort}";
      extraConfig = ''
        proxy_buffering off;
      '';
    };
  };
  deployment.keyys = [ <yori-nix/keys/http.muflax.key> ];
}
