{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
}:
let
  lock = (import ../../../packages.lock.nix).libplacebo;
  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch; };
  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };
  source = callPackage ../../utils/fetch-tarball/default.nix {
    name = "libplacebo-source-${lock.version}";
    inherit (lock) url sha256;
  };
in pkgs.stdenvNoCC.mkDerivation {
  pname = "libplacebo-${os}-${arch}";
  version = lock.version;
  src = source;
  dontUnpack = true;
  nativeBuildInputs = [ pkgs.meson pkgs.ninja pkgs.pkg-config pkgs.python3 ];
  # Meson's find_installation() selects Meson's interpreter, not a PATH wrapper.
  # Its generated commands must receive the template engine explicitly.
  PYTHONPATH = "${pkgs.python3Packages.jinja2}/${pkgs.python3.sitePackages}:${pkgs.python3Packages.markupsafe}/${pkgs.python3.sitePackages}";
  configurePhase = ''
    meson setup build $src --native-file ${nativeFile} --cross-file ${crossFile} \
      --prefix=$out --default-library=shared --wrap-mode=nodownload -Dauto_features=disabled -Ddovi=enabled -Ddemos=false -Dtests=false
  '';
  buildPhase = "meson compile -vC build";
  installPhase = "meson install -C build";
}
