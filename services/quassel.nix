{config, pkgs, lib, ...}:
{
  options.services.yorick.quassel = {
    enable = lib.mkEnableOption "quassel container";
  };
  config = lib.mkIf config.services.yorick.quassel.enable {
    containers.quassel = {
      config = { config, pkgs, ... }: {
        services.postgresql = {
          enable = true;
          package = pkgs.postgresql94;
          extraConfig = ''
            max_connections = 10
            shared_buffers = 1GB
            effective_cache_size = 4GB
            work_mem = 50MB
            maintenance_work_mem = 100MB
          '';
        };
        services.quassel = {
          # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/quassel.nix
          enable = true;
          interfaces = ["0.0.0.0"];
        };
        environment.systemPackages = [
          pkgs.quasselDaemon
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
  };
}
