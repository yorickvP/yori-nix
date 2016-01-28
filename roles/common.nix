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

  nix.binaryCaches = [
    https://hydra.nixos.org
  ];

  nix.trustedBinaryCaches = config.nix.binaryCaches;
  nix.binaryCachePublicKeys = ["hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=" ];

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
    
    # archiving
    xdelta
    atool
    unrar p7zip
    unzip zip

    # network
    nmap mtr
    socat netcat-openbsd
    lftp wget rsync

    git
    nix-repl
    rxvt_unicode.terminfo
  ];
  nix.gc.automatic = true;
}

