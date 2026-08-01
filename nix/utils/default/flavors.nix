# HIBIKI FORK: build only the `full` flavor.
#
# Hibiki consumes `-video-full` exclusively -- `default` omits the truehd/mlp
# decoder and makes TrueHD audio silent (BUG-073), and `encodersgpl` is unused.
#
# Dropping `encodersgpl` is also required to build FFmpeg 6.1.x here: it is the
# only flavor passing `--enable-filters`, which pulls in libavfilter/vf_scale_vt.c
# (new in 6.1). That file calls VTPixelTransferSession* APIs marked iOS 16.0+,
# while these frameworks target iOS 9.0, so -Werror=unguarded-availability-new
# turns it into a hard error. `full` enables only overlay and equalizer, so it
# never compiles that file. `encodersgpl` is also the only consumer of
# fftools-ffi, which is pinned to FFmpeg 6.0's internal fftools layout.
let
  flavors = import ../constants/flavors.nix;
in
[
  flavors.full
]
