let secrets = import <secrets>;
in
{ config, lib, pkgs, ... }:
{
  options.yorick.support32bit = with lib;
    mkOption { type = types.bool; default = false; };
  config = {
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
    driSupport32Bit = config.yorick.support32bit;
  };
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = config.yorick.support32bit;

  fonts = {
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      corefonts  # Micrsoft free fonts
      inconsolata  # monospaced
      source-code-pro
      ubuntu_font_family  # Ubuntu fonts
      source-han-sans-japanese
      iosevka
    ];
  };
  # spotify
  networking.firewall.allowedTCPPorts = [57621];
  networking.firewall.allowedUDPPorts = [57621];

  users.extraUsers.yorick.hashedPassword = secrets.yorick_hashedPassword;
  services.openssh.forwardX11 = true;
};
}
