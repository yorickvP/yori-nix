{ config, pkgs, lib, ...}:
{
	imports = [];
	time.timeZone = "Europe/Amsterdam";
	users.mutableUsers = false;
	users.extraUsers.root = {
		openssh.authorizedKeys.keys = config.users.extraUsers.yorick.openssh.authorizedKeys.keys;
	};
	users.extraUsers.yorick = {
	  isNormalUser = true;
	  uid = 1000;
	  extraGroups = ["wheel"];
	  group = "users";
	  openssh.authorizedKeys.keys = with (import ../sshkeys.nix); [yorick];
	};

  # Nix
  nixpkgs.config.allowUnfree = true;


  nix.trustedBinaryCaches = config.nix.binaryCaches ++ [http://hydra.cryp.to];
  nix.binaryCachePublicKeys = [
    "hydra.cryp.to-1:8g6Hxvnp/O//5Q1bjjMTd5RO8ztTsG8DKPOAg9ANr2g="
  ];

  nix.extraOptions = ''
    allow-unsafe-native-code-during-evaluation = true
    allow-unfree = true
  '';

  # Networking
  networking.enableIPv6 = false;

  services.openssh = {
  	passwordAuthentication = false;
  	challengeResponseAuthentication = false;
  };

  environment.systemPackages = with pkgs; [
    # v important.
    cowsay ponysay
    ed # ed, man!
    sl

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

