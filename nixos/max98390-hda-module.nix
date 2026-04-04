{ stdenvNoCC, lib, kernel, fetchFromGitHub, llvmPackages, gcc }:

let
  kernelUsesClang = (kernel.stdenv.cc.isClang or false);
  cc = if kernelUsesClang then llvmPackages.clang-unwrapped else gcc;
in

stdenvNoCC.mkDerivation {
  pname = "max98390-hda";
  version = "1.0-${kernel.version}";

  src = fetchFromGitHub {
    owner = "Andycodeman";
    repo = "samsung-galaxy-book-linux-fixes";
    rev = "v0.3.26";
    hash = "sha256-THezjEOxkaVnFY72zQyK2ER5VunOROm+i72JtSFCeMA=";
  };

  sourceRoot = "source/speaker-fix/src";

  nativeBuildInputs =
    kernel.moduleBuildDependencies
    ++ [ cc ]
    ++ lib.optionals kernelUsesClang [ llvmPackages.lld ];

  makeFlags = [
    "KVER=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ] ++ lib.optionals kernelUsesClang [
    "LLVM=1"
    "CC=${cc}/bin/clang"
    "LD=${llvmPackages.lld}/bin/ld.lld"
  ];

  installPhase = ''
    install -D snd-hda-scodec-max98390.ko $out/lib/modules/${kernel.modDirVersion}/extra/snd-hda-scodec-max98390.ko
    install -D snd-hda-scodec-max98390-i2c.ko $out/lib/modules/${kernel.modDirVersion}/extra/snd-hda-scodec-max98390-i2c.ko
  '';

  meta = with lib; {
    description = "MAX98390 HDA speaker amplifier driver for Samsung Galaxy Book4";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
