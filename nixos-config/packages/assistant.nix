{ stdenv, lib, fetchurl, dpkg, autoPatchelfHook, makeWrapper
, glib, gtk2, libv4l, alsa-lib, libpulseaudio, libGL
, libxkbcommon, fontconfig, freetype, dbus, pipewire
, xorg
}:

stdenv.mkDerivation rec {
  pname = "assistant";
  version = "6.5";

  src = fetchurl {
    url = "https://lk2.xn--80akicokc0aablc.xn--p1ai/WebApi/Platforms/Download/1375";
    sha256 = "19hs3fdk2csbl1p7s7fdc0bd857b7j1ci6yqv4jlsp7q366rqka6";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];

  buildInputs = [
    glib gtk2 libv4l alsa-lib libpulseaudio libGL pipewire
    libxkbcommon fontconfig freetype dbus
    xorg.libX11 xorg.libxcb xorg.libXext xorg.libXrandr xorg.libXrender
    xorg.libXfixes xorg.libXi xorg.libXtst xorg.libXcomposite xorg.libXdamage
    xorg.libXScrnSaver xorg.libXcursor stdenv.cc.cc.lib
  ];

  appendRunpaths = [ "${placeholder "out"}/opt/assistant/lib" ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin $out/share/applications $out/share/icons
    cp -r opt/assistant $out/opt/

    makeWrapper $out/opt/assistant/bin/assistant $out/bin/assistant \
      --chdir $out/opt/assistant/bin

    install -Dm644 opt/assistant/scripts/assistant.desktop \
      $out/share/applications/assistant.desktop
    substituteInPlace $out/share/applications/assistant.desktop \
      --replace-fail "/opt/assistant/scripts/assistant.sh" "$out/bin/assistant" \
      --replace-fail "/opt/assistant/share/icons/assistant.png" \
                     "$out/share/icons/assistant.png"

    install -Dm644 opt/assistant/share/icons/assistant.png \
      $out/share/icons/assistant.png

    runHook postInstall
  '';

  meta = with lib; {
    description = "Ассистент — российский клиент удалённого доступа (ГК САФИБ)";
    homepage = "https://xn--80akicokc0aablc.xn--p1ai/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
