[ (self: super: {
  gogitget = super.callPackage ./gogitget.nix {};
  shallot = super.callPackage ./shallot.nix {};
  yori-cc = super.callPackage ./yori-cc.nix {};
  firmware_qca6174 = super.callPackage ./firmware_qca6174.nix {};
  gitea = 
    super.gitea.overrideDerivation (o: rec {
      version = "1.4.1";
      name = "gitea-${version}";
      src = self.fetchFromGitHub {
        owner = "go-gitea";
        repo = "gitea";
        rev = "v${version}";
        sha256 = "1mid67c4021m7mi4ablx1w5v43831gzn8xpg8n30a4zmr70781wm";
      };
    });
})]
