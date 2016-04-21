# https://github.com/valeriangalliat/nixos-mailz
# manual actions:
# run sa-update
# configure DNS (dkim at /var/lib/dkim/*/default.txt)
# mkdir /var/empty/.spamassassin
# chown -R spamd /var/empty/.spamassassin
# possibly unneeded:
# chgrp -R vmail /var/spool/mail
# chmod g+rwx /var/spool/mail
# TODO: rspamd?
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mailz;

  # Convert:
  #
  #   {
  #     a = { aliases = [ "x", "y" ]; };
  #     b = { aliases = [ "x" ]; };
  #   }
  #
  # To:
  #
  #   {
  #     x = [ "a" "b" ];
  #     y = [ "a" ];
  #   }
  aliases = foldAttrs (user: users: [user] ++ users) [ ]
    (flatten (flip mapAttrsToList cfg.users
      (user: options: flip map options.aliases
        (alias: { ${alias} = user; }))));

  files = {
    credentials = pkgs.writeText "credentials"
      (concatStringsSep "\n"
        (flip mapAttrsToList cfg.users
          (user: options: "${user} ${options.password}")));

    # dovecot2
    users = pkgs.writeText "users"
      (concatStringsSep "\n"
        (flip mapAttrsToList cfg.users
          (user: options: "${user}:${options.password}:::::")));

    recipients = pkgs.writeText "recipients"
      (concatStringsSep "\n"
        (flip concatMap cfg.domains (domain:
          (map (user: "${user}@${domain}")
            (attrNames cfg.users ++ flatten ((flip mapAttrsToList) cfg.users
              (user: options: options.aliases)))))));

    aliases = pkgs.writeText "aliases"
      (concatStringsSep "\n"
        (flip mapAttrsToList aliases
          (alias: users: "${alias} ${concatStringsSep "," users}")));

    domains = pkgs.writeText "domains"
      (concatStringsSep "\n" cfg.domains);

    spamassassinSieve = pkgs.writeText "spamassassin.sieve" ''
      require "fileinto";
      if header :contains "X-Spam-Flag" "YES" {
        fileinto "Spam";
      }
    '';

    # From <https://github.com/OpenSMTPD/OpenSMTPD-extras/blob/master/extras/wip/filters/filter-regex/filter-regex.conf>
    regex = pkgs.writeText "filter-regex.conf" ''
      helo ! ^\[
      helo ^\.
      helo \.$
      helo ^[^\.]*$
    '';
  };

in

{
  options = {
    services.mailz = {
      domain = mkOption {
        default = cfg.networking.hostName;
        type = types.str;
        description = "Domain for this mail server.";
      };

      user = mkOption {
        default = "vmail";
        type = types.str;
      };

      group = mkOption {
        default = "vmail";
        type = types.str;
      };

      uid = mkOption {
        default = 2000;
        type = types.int;
      };

      gid = mkOption {
        default = 2000;
        type = types.int;
      };

      dkimDirectory = mkOption {
        default = "/var/lib/dkim";
        type = types.str;
        description = "Where to store DKIM keys.";
      };

      dkimBits = mkOption {
        type = types.int;
        default = 2048;
        description = "Size of the generated DKIM key.";
      };

      domains = mkOption {
        type = types.listOf types.str;
        description = "The domains to look for";
        example = ["example.com"];
      };

      keydir = mkOption {
        type = types.str;
        description = "The place to look for the ssl key";
        default = "${config.security.acme.directory}/${cfg.domain}";
        example = ["example.com"];
      };

      users = mkOption {
        default = { };
        type = types.loaOf types.optionSet;
        description = ''
          Attribute set of users.
        '';

        options = {
          password = mkOption {
            type = types.str;
            description = ''
              The user password, generated with
              <literal>smtpctl encrypt</literal>.
            '';
          };

          aliases = mkOption {
            type = types.listOf types.str;
            default = [ ];
            example = [ "postmaster" ];
            description = "A list of aliases for this user.";
          };
        };

        example = {
          "foo" = {
            password = "encrypted";
            aliases = [ "postmaster" ];
          };
          "bar" = {
            password = "encrypted";
          };
        };
      };
    };
  };

  config = mkIf (cfg.users != { }) {
    nixpkgs.config.packageOverrides = pkgs: {
      # opensmtpd = overrideDerivation pkgs.opensmtpd (oldAttrs: {
      #   # Needed to listen on both IPv4 and IPv6
      #   patches = oldAttrs.patches ++ [ ./opensmtpd.diff ];
      # });
      opensmtpd-extras = pkgs.opensmtpd-extras.override {
        # Needed to have PRNG working in chroot (for dkim-signer)
        openssl = pkgs.libressl;
      };
    };

    system.activationScripts.mailz = ''
      # Make sure SpamAssassin database is present
      if ! [ -d /etc/spamassassin ]; then
        cp -r ${pkgs.spamassassin}/share/spamassassin /etc
      fi

      # Make sure a DKIM private key exist
      if ! [ -d ${cfg.dkimDirectory}/${head cfg.domains} ]; then
        mkdir -p ${cfg.dkimDirectory}/${head cfg.domains}
        chmod 700 ${cfg.dkimDirectory}/${head cfg.domains}
        ${pkgs.opendkim}/bin/opendkim-genkey --bits ${toString cfg.dkimBits} --domain ${head cfg.domains} --directory ${cfg.dkimDirectory}/${head cfg.domains}
      fi
    '';

    services.spamassassin.enable = true;
    # it turns out that the dkim header domain does not have to match the from address
    # but it would be a nice-to-have
    services.opensmtpd = {
      enable = true;
      serverConfiguration = ''
        filter filter-pause pause
        filter filter-regex regex "${files.regex}"
        filter filter-spamassassin spamassassin "-saccept"
        filter filter-dkim-signer dkim-signer "-d${head cfg.domains}" "-p${cfg.dkimDirectory}/${head cfg.domains}/default.private"
        filter in chain filter-pause filter-regex filter-spamassassin
        filter out chain filter-dkim-signer

        pki ${cfg.domain} certificate "${cfg.keydir}/fullchain.pem"
        pki ${cfg.domain} key "${cfg.keydir}/key.pem"

        table credentials file:${files.credentials}
        table recipients file:${files.recipients}
        table aliases file:${files.aliases}
        table domains file:${files.domains}

        listen on 0.0.0.0 port 25 hostname ${cfg.domain} filter in tls pki ${cfg.domain}
        #listen on :: port 25 hostname ${cfg.domain} filter in tls pki ${cfg.domain}
        listen on 0.0.0.0 port 587 hostname ${cfg.domain} filter out tls-require pki ${cfg.domain} auth <credentials>
        #listen on :: port 587 hostname ${cfg.domain} filter out tls-require pki ${cfg.domain} auth <credentials>
        enqueuer filter out

        accept from any for domain <domains> recipient <recipients> alias <aliases> deliver to lmtp localhost:24
        accept from local for any relay
      '';
      procPackages = [ pkgs.opensmtpd-extras ];
    };

    services.dovecot2 = {
      enable = true;
      enablePop3 = false;
      enableLmtp = true;
      mailLocation = "maildir:/var/spool/mail/%n";
      mailUser = cfg.user;
      mailGroup = cfg.group;
      modules = [ pkgs.dovecot_pigeonhole ];
      sslServerCert = "${cfg.keydir}/fullchain.pem";
      sslServerKey = "${cfg.keydir}/key.pem";
      enablePAM = false;
      sieveScripts = { before = files.spamassassinSieve; };
      extraConfig = ''
        postmaster_address = postmaster@${head cfg.domains}

        service lmtp {
          inet_listener lmtp {
            address = 127.0.0.1 ::1
            port = 24
          }
        }

        userdb {
          driver = passwd-file
          args = username_format=%n ${files.users}
          default_fields = uid=${cfg.user} gid=${cfg.user} home=/var/spool/mail/%n
        }

        passdb {
          driver = passwd-file
          args = username_format=%n ${files.users}
        }

        namespace inbox {
          inbox = yes

          mailbox Sent {
              auto = subscribe
              special_use = \Sent
          }

          mailbox Drafts {
              auto = subscribe
              special_use = \Drafts
          }

          mailbox Spam {
              auto = create
              special_use = \Junk
          }

          mailbox Trash {
              auto = subscribe
              special_use = \Trash
          }

          mailbox Archive {
              auto = subscribe
              special_use = \Archive
          }
        }

        protocol lmtp {
          mail_plugins = $mail_plugins sieve
        }
      '';
    };

    users.extraUsers = optional (cfg.user == "vmail") {
      name = "vmail";
      uid = cfg.uid;
      group = cfg.group;
    };

    users.extraGroups = optional (cfg.group == "vmail") {
      name = "vmail";
      gid = cfg.gid;
    };

    networking.firewall.allowedTCPPorts = [ 25 587 993 ];
  };
}
