{ config, lib, pkgs, ... }:
{
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    synaptics = {
      twoFingerScroll = true;
      horizontalScroll = true;
      scrollDelta = -107; # inverted scrolling
    };
    libinput = {
      naturalScrolling = true;
      tappingDragLock = false;
    };
    layout = "us";
    displayManager.slim.defaultUser = "yorick";
    # xkbOptions = "eurosign:e";
    windowManager.i3 = {
      enable = true;
    } // (if (lib.versionAtLeast config.system.nixosRelease "17.03") then {
      package = pkgs.i3-gaps;
      } else {});
  };
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;

  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      corefonts  # Micrsoft free fonts
      inconsolata  # monospaced
      source-code-pro
      ubuntu_font_family  # Ubuntu fonts
      source-han-sans-japanese
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
  # spotify
  networking.firewall.allowedTCPPorts = [57621];
  networking.firewall.allowedUDPPorts = [57621];
}
