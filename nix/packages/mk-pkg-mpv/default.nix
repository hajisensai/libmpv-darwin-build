{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
  variant ? import ../../utils/default/variant.nix,
}:
if variant == "video"
then import ./video.nix { inherit pkgs os arch variant; }
else import ./legacy.nix { inherit pkgs os arch variant; }
