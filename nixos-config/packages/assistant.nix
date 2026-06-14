{ stdenv, lib, fetchurl, dpkg, buildFHSEnv, writeShellScript
, glib, gtk2, libv4l, alsa-lib, libpulseaudio, libGL, pipewire
, libxkbcommon, fontconfig, freetype, dbus, openssl, curl
, xorg
}:

let
  pname = "assistant";
  version = "6.5";

  # Lazarus/FPC бинарь от ГК САФИБ собран под Debian-like окружение.
  # autoPatchelfHook ломает совместимость bundled libs из /opt/assistant/lib
  # (libstdc.so.6.0.31, bundled libssl/libcrypto) с системными nixpkgs-
  # эквивалентами, что приводит к heap overflow (RTE 203) в TGtk2WidgetSet.
  # Поэтому раскладываем .deb «как есть» без патчинга и запускаем внутри
  # FHS sandbox через buildFHSEnv.
  rawData = stdenv.mkDerivation {
    name = "${pname}-${version}-raw";
    src = fetchurl {
      url = "https://lk2.xn--80akicokc0aablc.xn--p1ai/WebApi/Platforms/Download/1375";
      sha256 = "19hs3fdk2csbl1p7s7fdc0bd857b7j1ci6yqv4jlsp7q366rqka6";
    };
    nativeBuildInputs = [ dpkg ];
    dontPatchELF = true;
    dontStrip = true;
    dontAutoPatchelf = true;
    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      mkdir -p $out
      cp -r opt $out/
    '';
  };

  launchScript = writeShellScript "assistant-launch" ''
    cd ${rawData}/opt/assistant/bin
    export LD_LIBRARY_PATH="${rawData}/opt/assistant/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec ./assistant "$@"
  '';
in

buildFHSEnv {
  inherit pname version;

  targetPkgs = pkgs: with pkgs; [
    bashInteractive coreutils
    glib gtk2 gdk-pixbuf pango cairo atk at-spi2-core harfbuzz
    libv4l alsa-lib libpulseaudio libGL pipewire
    libxkbcommon fontconfig freetype dbus openssl curl sqlite zlib
    libjpeg libpng libtiff libxml2 libxslt libsoup_2_4
    nss nspr expat efivar
    xorg.libX11 xorg.libxcb xorg.libXext xorg.libXrandr xorg.libXrender
    xorg.libXfixes xorg.libXi xorg.libXtst xorg.libXcomposite xorg.libXdamage
    xorg.libXScrnSaver xorg.libXcursor xorg.libXft xorg.libxshmfence
    xorg.libXinerama
    util-linux.lib  # libuuid для libusbast.so
    stdenv.cc.cc.lib

    # Core X11 bitmap fonts — нужны для XLoadFont() в окне удалённого desktop.
    # Без них Ассистент пишет "Can not load the font" и показывает серый экран.
    xorg.fontmiscmisc xorg.fontcursormisc
    xorg.fontadobe75dpi xorg.fontadobe100dpi
    xorg.fontbh75dpi xorg.fontbh100dpi
    xorg.fontbhlucidatypewriter75dpi xorg.fontbhlucidatypewriter100dpi
    xorg.fontbhttf xorg.fontbitstream100dpi xorg.fontbitstream75dpi
    dejavu_fonts liberation_ttf
  ];

  runScript = launchScript;

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/icons
    install -Dm644 ${rawData}/opt/assistant/scripts/assistant.desktop \
      $out/share/applications/assistant.desktop
    substituteInPlace $out/share/applications/assistant.desktop \
      --replace-fail "/opt/assistant/scripts/assistant.sh" "$out/bin/assistant" \
      --replace-fail "/opt/assistant/share/icons/assistant.png" \
                     "$out/share/icons/assistant.png"
    install -Dm644 ${rawData}/opt/assistant/share/icons/assistant.png \
      $out/share/icons/assistant.png
  '';

  meta = with lib; {
    description = "Ассистент — российский клиент удалённого доступа (ГК САФИБ)";
    homepage = "https://xn--80akicokc0aablc.xn--p1ai/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
