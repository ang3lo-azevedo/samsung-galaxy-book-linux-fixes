# Flips Samsung Galaxy Book camera sensors that are physically mounted
# upside down but whose rotation is never reported to userspace, so apps
# show the image 180 degrees off. This affects convertible models (NP960QHA,
# NP960QFG, NP960QGK, ...) where the bundled ipu-bridge kernel module
# override does not engage, e.g. when running the native in-tree
# intel-ipu7 stack without the webcam-fix-book5 libcamera relay.
#
# Instead of touching libcamera, this applies the flip at the V4L2 subdev
# level: setting HFLIP + VFLIP equals a 180 degree rotation, and the sensor
# driver's modify-layout flag keeps the Bayer order correct, so colors stay
# accurate for every consumer (libcamera/PipeWire apps and plain V4L2 apps
# alike).
#
#   hardware.samsungGalaxyBook.webcamSensorFlip.enable = true;
#
{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.samsungGalaxyBook.webcamSensorFlip;
in
{
  options.hardware.samsungGalaxyBook.webcamSensorFlip = {
    enable = lib.mkEnableOption ''
      flipping Galaxy Book camera sensors that are physically mounted upside
      down, applied at the V4L2 subdev level as soon as the sensor binds
    '';

    i2cId = lib.mkOption {
      type = lib.types.str;
      default = "OVTI02E1:00";
      example = "OVTI02C1:00";
      description = ''
        I2C client id of the sensor to flip, as it appears in the device's
        udev DEVPATH (e.g. OVTI02E1:00 for the Galaxy Book5 OV02E10 sensor,
        OVTI02C1:00 for the Book3/Book4 OV02C10 sensor). Used to match the
        sensor's v4l2-subdev ancestor device in the udev rule.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      # Flip sensors that are mounted upside down but report rotation=0.
      ACTION=="add", KERNEL=="v4l-subdev*", SUBSYSTEM=="video4linux", KERNELS=="*${cfg.i2cId}", \
        RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/%k --set-ctrl=horizontal_flip=1 --set-ctrl=vertical_flip=1"
    '';
  };
}
