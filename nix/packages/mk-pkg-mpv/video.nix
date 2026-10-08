{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
  variant ? import ../../utils/default/variant.nix,
  flavor ? import ../../utils/default/flavor.nix,
}:
let
  lock = (import ../../../packages.lock.nix).mpv-menu;
  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch variant flavor; };
  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };
  xctoolchainLipo = callPackage ../../utils/xctoolchain/lipo.nix { };
  src = callPackage ../../utils/fetch-tarball/default.nix {
    name = "mpv-menu-source-${lock.version}";
    inherit (lock) url sha256;
  };
  patchedSource = pkgs.runCommand "mpv-menu-source-patched" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    cp -r ${src} source
    chmod -R u+w source
    cd source
    patchShebangs .
    patch -p1 <${../../../patches/mpv-darwin-cross-sdk.patch}
    patch -p1 <${../../../patches/mpv-audiounit-shared-session-menu.patch}
    patch -p1 <${../../../patches/mpv-gl-dovi-p5-menu.patch}
    patch -p1 <${../../../patches/disc-navigation-state.patch}
    cp -r . $out
  '';
in pkgs.stdenvNoCC.mkDerivation {
  pname = "mpv-menu-${os}-${arch}";
  version = lock.version;
  src = patchedSource;
  dontUnpack = true;
  nativeBuildInputs = [ pkgs.meson pkgs.ninja pkgs.pkg-config pkgs.python3 xctoolchainLipo ];
  buildInputs = builtins.map (path: callPackage path { }) [
    ../mk-pkg-ffmpeg/default.nix
    ../mk-pkg-libass/default.nix
    ../mk-pkg-uchardet/default.nix
    ../mk-pkg-libplacebo/default.nix
    ../mk-pkg-libbluray/default.nix
  ];
  configurePhase = ''
    OPTIONS=(-Db_lundef=true -Dauto_features=disabled -Dgpl=false -Dcplayer=false -Dlibmpv=true
      -Diconv=enabled -Duchardet=enabled -Dzlib=enabled -Dgl=enabled
      -Dplain-gl=enabled -Dlibbluray=enabled)
    if [ "${os}" = macos ]; then
      OPTIONS+=(-Dcoreaudio=enabled -Dcocoa=enabled -Dgl-cocoa=enabled -Dvideotoolbox-gl=enabled)
    else
      OPTIONS+=(-Daudiounit=enabled -Dios-gl=enabled)
    fi
    meson setup build $src --native-file ${nativeFile} --cross-file ${crossFile} \
      --prefix=$out --wrap-mode=nofallback "''${OPTIONS[@]}" | tee configure.log
  '';
  buildPhase = "meson compile -vC build";
  installPhase = ''
    meson install -C build
    mkdir -p $out/share/mpv
    cp configure.log $out/share/mpv/
  '';
}
