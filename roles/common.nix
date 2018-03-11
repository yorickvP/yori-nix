let secrets = import <secrets>;
in
{ config, pkgs, lib, ...}:
let
  machine = with lib; head (splitString "." config.networking.hostName);
in
{
	imports = [
    ../roles/hardware.nix
    ../modules/tor-hidden-service.nix
    ../modules/nginx.nix
    ../roles/pub.nix
    ../roles/quassel.nix
    ../roles/gogs.nix
    ../roles/mail.nix
    ../roles/website.nix
    ../roles/xmpp.nix
  ];
	time.timeZone = "Europe/Amsterdam";
	users.mutableUsers = false;
	users.extraUsers.root = {
		openssh.authorizedKeys.keys = config.users.extraUsers.yorick.openssh.authorizedKeys.keys;
    # root password is useful from console, ssh has password logins disabled
    hashedPassword = secrets.pennyworth_hashedPassword; # TODO: generate own

	};
  services.timesyncd.enable = true;
  services.fail2ban.enable = true;
	users.extraUsers.yorick = {
	  isNormalUser = true;
	  uid = 1000;
	  extraGroups = ["wheel"];
	  group = "users";
	  openssh.authorizedKeys.keys = with (import ../sshkeys.nix); [yorick];
	};

  # Nix
  nixpkgs.config.allowUnfree = true;
  nix.package = pkgs.nixUnstable;

  nix.buildCores = config.nix.maxJobs;

  nix.extraOptions = ''
    allow-unsafe-native-code-during-evaluation = true
  '';

  # Networking
  networking.enableIPv6 = false;

  services.openssh = {
    enable = true;
  	passwordAuthentication = false;
  	challengeResponseAuthentication = false;
  };

  services.tor = {
    enable = true;
    client.enable = true;
    # ssh hidden service
    hiddenServices.ssh.map = [{ port = 22; }];
    service-keys.ssh = "/run/keys/torkeys/ssh.${machine}.key";
  };

  programs.ssh.extraConfig = ''
    Host *.onion
      ProxyCommand nc -xlocalhost:9050 -X5 %h %p
  '' +
  (with lib; (flip concatMapStrings) (filter (hasPrefix "ssh.") (attrNames secrets.tor_hostnames)) (name: ''
    Host ${removePrefix "ssh." name}.onion
        hostname ${secrets.tor_hostnames.${name}}
    ''
    ));

  environment.systemPackages = with pkgs; [
    # v important.
    cowsay ponysay
    ed # ed, man!
    sl
    rlwrap

    vim

    # system stuff
    ethtool inetutils
    pciutils usbutils
    iotop powertop htop
    psmisc lsof
    smartmontools hdparm
    lm_sensors
    ncdu
    
    # utils
    file which
    reptyr
    tmux
    bc
    mkpasswd
    shadow
    
    # archiving
    xdelta
    atool
    unrar p7zip
    unzip zip

    # network
    nmap mtr bind
    socat netcat-openbsd
    lftp wget rsync

    git
    nix-repl
    rxvt_unicode.terminfo
  ];
  nix.gc.automatic = true;

}

