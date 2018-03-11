{ pkgs, lib, config, ... }:
with lib;
let cfg = config.deployment.keyys; in
{
  options.deployment.keyys = mkOption { type = types.listOf types.path; default = []; };
  options.deployment.keys-copy = mkOption { type = types.package; };
  config = {
    deployment.keys-copy = pkgs.writeShellScriptBin "copy-keys" (if cfg != [] then ''
      set -e
      ssh root@$1 "mkdir -p /root/keys"
      scp ${concatMapStringsSep " " toString cfg} root@$1:/root/keys
      echo "uploaded keys"
    '' else ''
      echo "no keys to upload"
    '');
    
  };
    
}
