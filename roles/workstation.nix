{ config, lib, pkgs, ... }:
{
  imports = [
    ../roles/graphical.nix
  ];
  users.extraUsers.yorick.extraGroups = ["input"];
  services.redshift = {
    enable = true;
    latitude = "51.8";
    longitude = "5.8";
    temperature = {
      day = 6500;
      night = 5500;
    };
  };
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint ];
  };
  environment.systemPackages = [pkgs.ghostscript];
  services.xserver.displayManager.sessionCommands = ''
    gpg-connect-agent /bye
    unset SSH_AGENT_PID
    export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh"
  '';
  virtualisation.virtualbox.host.enable = true;
  yorick.support32bit = true;
}
