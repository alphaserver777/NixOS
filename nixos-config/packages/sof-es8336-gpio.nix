{ lib, kernel }:

# Задача 021: GPIO на Huawei BOD-WXX9 должны освобождаться при удалении
# платы и при ошибке probe. Собираем один модуль с ABI выбранного ядра.
kernel.stdenv.mkDerivation {
  pname = "sof-es8336-gpio";
  version = kernel.version;
  src = kernel.src;

  nativeBuildInputs = kernel.moduleBuildDependencies;
  hardeningDisable = [ "pic" ];

  unpackPhase = ''
    runHook preUnpack
    mkdir source
    tar -xf "$src" --strip-components=5 -C source \
      linux-${kernel.version}/sound/soc/intel/boards/sof_es8336.c \
      linux-${kernel.version}/sound/soc/intel/boards/hda_dsp_common.h
    sourceRoot=source
    runHook postUnpack
  '';

  patches = [ ./sof-es8336-gpio.patch ];

  buildPhase = ''
    runHook preBuild
    printf '%s\n' 'obj-m := snd-soc-sof-es8336.o' \
      'snd-soc-sof-es8336-y := sof_es8336.o' > Makefile
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M="$PWD" modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm444 snd-soc-sof-es8336.ko \
      "$out/lib/modules/${kernel.modDirVersion}/updates/snd-soc-sof-es8336.ko"
    runHook postInstall
  '';

  meta = {
    description = "SOF ES8336 machine driver with GPIO cleanup fixes";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
