let secrets = import <secrets>;
in
{ config, lib, pkgs, ... }:
{
  imports = [ <yori-nix/roles> ];
  options.yorick.support32bit = with lib;
    mkOption { type = types.bool; default = false; };
  config = {
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    libinput = {
      naturalScrolling = true;
      tappingDragLock = false;
    };
    layout = "us";
    xkbOptions = "caps:escape";
    displayManager.slim.defaultUser = "yorick";
    # xkbOptions = "eurosign:e";
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
    };
  };
    hardware.opengl = {
      enable = true;
      driSupport32Bit = config.yorick.support32bit;
    };
    sound.enable = true;
    hardware.pulseaudio = {
      enable = true;
      support32Bit = config.yorick.support32bit;
    };
  users.extraUsers.yorick.extraGroups = ["video"];
    # fix backlight permissions
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

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
  networking.firewall.allowedTCPPorts = [55025 57621];
  networking.firewall.allowedUDPPorts = [55025 57621];

  users.extraUsers.yorick.hashedPassword = secrets.yorick_hashedPassword;
  services.openssh.forwardX11 = true;
};
}
