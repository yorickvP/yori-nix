{lib, fetchurl, lua, sqlite, luaPackages,
  libpsql ? null, libmysql ? null,
  withpsql ? false, withmysql ? false}:

assert withpsql -> libpsql != null;
assert withmysql -> libmysql != null;

luaPackages.buildLuaPackage rec {
  version = "0.5";
  name = "luadbi-${version}";
  isLibrary = true;
  src = fetchurl {
    url = "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/luadbi/luadbi.${version}.tar.gz";
    sha256 = "07ikxgxgfpimnwf7zrqwcwma83ss3wm2nzjxpwv2a1c0vmc684a9";
  };
  
  propagatedBuildInputs = [ sqlite ]
    ++ (lib.optional withpsql [libpsql])
    ++ (lib.optional withmysql [libmysql]);

  unpackPhase = ''
    mkdir ./luadbi
    tar -xf $src -C ./luadbi
    sourceRoot=./luadbi
    chmod -R u+w "$sourceRoot";
  '';

  preBuild = with lib.optionalString; ''
    makeFlagsArray=(
      sqlite3
      ${lib.optionalString withpsql "psql"}
      ${lib.optionalString withmysql "mysql"}
      LUA_LDIR="$out/share/lua/${lua.luaversion}"
      LUA_INC="-I${lua}/include" LUA_CDIR="$out/lib/lua/${lua.luaversion}"
      )
  '';

  installPhase = ''
    mkdir -p $out/lib/lua/${lua.luaversion}
    install -p ./*.so DBI.lua $out/lib/lua/${lua.luaversion}
  '';

  meta = {
    homepage = "https://code.google.com/archive/p/luadbi/downloads";
    maintainers = [ "Yorick" ];
  };
}
