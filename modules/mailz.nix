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
  
  alldomains = lib.concatLists (mapAttrsToList (n: usr: usr.domains) cfg.users);

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

    domains = pkgs.writeText "domains"
      (concatStringsSep "\n" alldomains);

    spamassassinSieve = pkgs.writeText "spamassassin.sieve" ''
      require "fileinto";
      if header :contains "X-Spam-Flag" "YES" {
        fileinto "Spam";
      }
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

      mainUser = mkOption {
        example = "root";
        type = types.str;
      };

      keydir = mkOption {
        type = types.str;
        description = "The place to look for the ssl key";
        default = "${config.security.acme.directory}/${cfg.domain}";
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
          domains = mkOption {
            type = types.listOf types.str;
            example = ["example.com"];
          };

        };

        example = {
          "foo" = {
            password = "encrypted";
          };
          "bar" = {
            password = "encrypted";
          };
        };
      };
    };
  };

  config = mkIf (cfg.users != { }) {
    system.activationScripts.mailz = ''
      # Make sure SpamAssassin database is present
      #if ! [ -d /etc/spamassassin ]; then
      #  cp -r ${pkgs.spamassassin}/share/spamassassin /etc
      #fi

      # Make sure a DKIM private key exist
      if ! [ -d ${cfg.dkimDirectory} ]; then
        mkdir -p ${cfg.dkimDirectory}
        chmod 700 ${cfg.dkimDirectory}
        chown ${config.services.rmilter.user} ${cfg.dkimDirectory}
      fi
      # Generate missing keys
      '' +
      (lib.concatMapStringsSep "\n" (domain: ''
      if ! [ -e ${cfg.dkimDirectory}/${domain}.default.key ]; then
        ${pkgs.opendkim}/bin/opendkim-genkey --bits ${toString cfg.dkimBits} --domain ${domain} --directory ${cfg.dkimDirectory} --selector default
        mv ${cfg.dkimDirectory}/default.private ${cfg.dkimDirectory}/${domain}.default.key 
        mv ${cfg.dkimDirectory}/default.txt ${cfg.dkimDirectory}/${domain}.default.txt
        chown ${config.services.rmilter.user} ${cfg.dkimDirectory}/${domain}.default.*
      fi
      '') alldomains);
    services.rspamd.enable = true;
    services.rmilter = {
      enable = true;
      socketActivation = false;
      #debug = true;
      rspamd.enable = true;
      postfix.enable = true;
      extraConfig = ''
        dkim {
            domain {
              key = ${cfg.dkimDirectory};
              domain = "*";
              selector = "default";
            };
            header_canon = relaxed;
            body_canon = relaxed;
            sign_alg = sha256;
        };
      '';
    };

    services.postfix = {
      enable = true;
      destination = alldomains ++ ["$myhostname" "localhost.$mydomain" "$mydomain" "localhost"];
      sslCert = "${cfg.keydir}/fullchain.pem";
      sslKey = "${cfg.keydir}/key.pem";
      postmasterAlias = cfg.mainUser;
      enableSubmission = true;
      virtual = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: usr:
        lib.concatMapStringsSep "\n" (dom: "@${dom} ${name}") usr.domains) cfg.users);
      extraConfig = ''
        mailbox_transport = lmtp:unix:dovecot-lmtp
      '';
      submissionOptions = {
        "smtpd_tls_security_level" = "encrypt";
        "smtpd_sasl_auth_enable" = "yes";
        "smtpd_sasl_type" = "dovecot";
        "smtpd_sasl_path" = "/var/lib/postfix/auth";
        "smtpd_client_restrictions" = "permit_sasl_authenticated,reject";
        #"milter_macro_daemon_name" = "ORIGINATING";
      };
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
        postmaster_address = postmaster@${head alldomains}

        service lmtp {
          unix_listener /var/lib/postfix/queue/dovecot-lmtp {
            mode = 0660
            user = postfix
            group = postfix        
          }
        }
        service auth {
          unix_listener /var/lib/postfix/auth {
            mode = 0660
            # Assuming the default Postfix user and group
            user = postfix
            group = postfix        
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
