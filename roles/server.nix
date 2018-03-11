{
  imports = [ <yori-nix/roles> ];
  
  services.nixosManual.enable = false;

  environment.noXlibs = true;

}
