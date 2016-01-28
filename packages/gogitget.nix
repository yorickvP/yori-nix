# this is the secure fetchgit, but it actually works
{ fetchgit, writeScript, openssh, stdenv }: args: derivation ((fetchgit args).drvAttrs // {
  SSH_AUTH_SOCK = if (builtins.tryEval <ssh-auth-sock>).success
    then builtins.toString <ssh-auth-sock>
    else null;
  GIT_SSH = writeScript "fetchgit-ssh" ''
    #! ${stdenv.shell}
    TEMP_ID=$(mktemp)
    cp ${let
      sshIdFile = if (builtins.tryEval <ssh-id-file>).success
        then <ssh-id-file>
        else builtins.trace ''
          That didn't work.
        '' "/var/lib/empty/config";
    in builtins.toString sshIdFile} $TEMP_ID
    chown `whoami` $TEMP_ID
    chmod 400 $TEMP_ID
    exec -a ssh ${openssh}/bin/ssh -i $TEMP_ID -o StrictHostKeyChecking=no "$@"
  '';
})
