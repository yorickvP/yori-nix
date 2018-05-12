[ (self: super: {
  gogitget = super.callPackage ./gogitget.nix {};
  shallot = super.callPackage ./shallot.nix {};
  yori-cc = super.callPackage ./yori-cc.nix {};
  firmware_qca6174 = super.callPackage ./firmware_qca6174.nix {};

})]
