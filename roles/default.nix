let secrets = import <secrets>;
in
{ config, pkgs, lib, ...}:
let
  machine = lib.removeSuffix ".nix" (builtins.baseNameOf <nixos-config>);
in
{
	imports = [
    ../modules/tor-hidden-service.nix
    ../modules/nginx.nix
    <yori-nix/deploy/keys.nix>
    <yori-nix/services>
  ];
  networking.hostName = secrets.hostnames.${machine};
	time.timeZone = "Europe/Amsterdam";
	users.mutableUsers = false;
	users.extraUsers.root = {
		openssh.authorizedKeys.keys = config.users.extraUsers.yorick.openssh.authorizedKeys.keys;
    # root password is useful from console, ssh has password logins disabled
    hashedPassword = secrets.pennyworth_hashedPassword; # TODO: generate own

	};
  services.timesyncd.enable = true;
  services.fail2ban.enable = true;
  # ban repeat offenders longer
  services.fail2ban.jails.recidive = ''
    filter = recidive
    action = iptables-allports[name=recidive]
    maxretry = 5
    bantime = 604800 ; 1 week
    findtime = 86400 ; 1 day
  '';
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
  nixpkgs.overlays = import ../packages;

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
    service-keys.ssh = "/root/keys/ssh.${machine}.key";
  };
  deployment.keyys = [ (<yori-nix/keys> + "/ssh.${machine}.key") ];

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

