{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
}:
let
  lock = (import ../../../packages.lock.nix).libbluray;
  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch; };
  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };
  source = callPackage ../../utils/fetch-tarball/default.nix {
    name = "libbluray-source-${lock.version}";
    inherit (lock) url sha256;
  };
  patchedSource = pkgs.runCommand "libbluray-darwin-source" { } ''
    cp -r ${source} source
    chmod -R u+w source
    cd source
    patch -p1 <${../../../patches/libbluray-ios-files.patch}
    cp -r . $out
  '';
in pkgs.stdenvNoCC.mkDerivation {
  pname = "libbluray-${os}-${arch}";
  version = lock.version;
  src = patchedSource;
  dontUnpack = true;
  nativeBuildInputs = [ pkgs.meson pkgs.ninja pkgs.pkg-config pkgs.python3 ];
  configurePhase = ''
    meson setup build $src --native-file ${nativeFile} --cross-file ${crossFile} \
      --prefix=$out --default-library=shared --wrap-mode=nodownload -Dbdj_jar=disabled -Denable_tools=false -Denable_examples=false -Dfontconfig=disabled -Dfreetype=disabled -Dlibxml2=disabled -Dembed_udfread=true
  '';
  buildPhase = "meson compile -vC build";
  installPhase = "meson install -C build";
}
