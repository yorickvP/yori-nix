{config, pkgs, lib, ...}:
{
  containers.quassel = {
    config = { config, pkgs, ... }: {
      services.postgresql.enable = true;
      services.postgresql.package = pkgs.postgresql94;
      services.quassel = {
        # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/quassel.nix
        enable = true;
        interface = "0.0.0.0";
      };
      environment.systemPackages = [
        pkgs.quasselDaemon_qt5
      ];
      networking.firewall.allowedTCPPorts = [4242];
    };
    privateNetwork = true;
    hostAddress = "192.168.125.1";
    localAddress = "192.168.125.11";
  };
  # give the containers networking
  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-+"];
    externalInterface = "enp2s0";
    forwardPorts = [
      { sourcePort = 4242; destination = "192.168.125.11:4242"; }
    ];    
  };
  networking.firewall.allowedTCPPorts = [4242];
}
