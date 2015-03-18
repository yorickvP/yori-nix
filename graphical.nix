{ config, lib, pkgs, ... }:
{
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    synaptics = {
      twoFingerScroll = true;
      # inverted scrolling
      additionalOptions = ''
        Option "HorizScrollDelta" "-107"
        Option "VertScrollDelta" "-107"
      '';
    };
    layout = "us";
    displayManager.slim.defaultUser = "yorick";
    # xkbOptions = "eurosign:e";
  };
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  environment.systemPackages = with pkgs; [
    slock
  ];
  security.setuidPrograms = [ "slock" ];

  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      corefonts  # Micrsoft free fonts
      inconsolata  # monospaced
      source-code-pro
      ubuntu_font_family  # Ubuntu fonts
    ];
  };
  services.redshift = {
    enable = true;
    latitude = "51.8";
    longitude = "5.8";
    temperature = {
      day = 6500;
      night = 5500;
    };
  };
}
