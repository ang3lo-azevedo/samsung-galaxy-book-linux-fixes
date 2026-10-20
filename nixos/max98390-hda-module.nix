{
  stdenvNoCC,
  lib,
  kernel,
  fetchFromGitHub,
  llvmPackages,
  gcc,
  xz,
  sourceType ? "github",
  localSrc ? ../speaker-fix/src,
  githubOwner ? "Andycodeman",
  githubRepo ? "samsung-galaxy-book-linux-fixes",
  githubRev ? "v0.3.26",
  githubHash ? "sha256-THezjEOxkaVnFY72zQyK2ER5VunOROm+i72JtSFCeMA=",
}:

let
  kernelUsesClang = kernel.stdenv.cc.isClang or false;
  cc = if kernelUsesClang then llvmPackages.clang-unwrapped else gcc;
  src = if sourceType == "local" then localSrc else fetchFromGitHub {
    owner = githubOwner;
    repo = githubRepo;
    rev = githubRev;
    hash = githubHash;
  };
in

stdenvNoCC.mkDerivation {
  pname = "max98390-hda";
  version = "1.0-${kernel.version}";

  inherit src;
  sourceRoot = lib.optionalString (sourceType == "github") "source/speaker-fix/src";

  nativeBuildInputs =
    kernel.moduleBuildDependencies
    ++ [ cc xz ]
    ++ lib.optionals kernelUsesClang [ llvmPackages.lld ];

  makeFlags = [
    "KVER=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ] ++ lib.optionals kernelUsesClang [
    "LLVM=1"
    "CC=${cc}/bin/clang"
    "LD=${llvmPackages.lld}/bin/ld.lld"
  ];

  # Through modules_install for the .ko.cer newer nixpkgs needs (see webcam-fix-book5.nix)
  installPhase = ''
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD \
      ${lib.escapeShellArgs kernel.commonMakeFlags} \
      INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=extra DEPMOD=true modules_install
  '';

  meta = with lib; {
    description = "MAX98390 HDA speaker amplifier driver for Samsung Galaxy Book4";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
