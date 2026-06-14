{ stdenv, lib, fetchurl, dpkg, autoPatchelfHook, makeWrapper
, openssl, glib, alsa-lib, libpulseaudio, libGL, libxkbcommon
, fontconfig, freetype, dbus, libdrm, mesa
, libgpg-error, libkrb5, e2fsprogs, qt6
, xorg
}:

stdenv.mkDerivation rec {
  pname = "happ";
  version = "2.17.1";

  src = fetchurl {
    url = "https://github.com/Happ-proxy/happ-desktop/releases/download/${version}/Happ.linux.x64.deb";
    sha256 = "1gm1zjjvfvnmqcsp03x05i9kkidr9i6ccsih4m2zzinlshlybfg5";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];

  buildInputs = [
    openssl glib alsa-lib libpulseaudio libGL libxkbcommon
    fontconfig freetype dbus libdrm mesa stdenv.cc.cc.lib
    libgpg-error libkrb5 e2fsprogs qt6.qtwayland
    xorg.libX11 xorg.libxcb xorg.libXext xorg.libXrandr xorg.libXrender
    xorg.libXfixes xorg.libXi xorg.libXtst xorg.libXcomposite xorg.libXdamage
    xorg.libXcursor xorg.libxkbfile
    xorg.xcbutil xorg.xcbutilimage xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil xorg.xcbutilwm xorg.xcbutilcursor
  ];

  appendRunpaths = [ "${placeholder "out"}/opt/happ/lib" ];

  dontWrapQtApps = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin
    cp -r opt/happ $out/opt/

    # Принудительно перебиваем стиль — у пользователя в окружении может стоять
    # QT_STYLE_OVERRIDE=kvantum (например, от Stylix), но Happ ожидает QML-модуль
    # "kvantum", которого нет в bundled lib/qml/ и в nixpkgs (kvantum под Qt5
    # only). Без Fusion Main.qml не загружается и приложение мгновенно exits.
    makeWrapper $out/opt/happ/bin/Happ $out/bin/happ \
      --chdir $out/opt/happ/bin \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ openssl ]} \
      --set QT_STYLE_OVERRIDE Fusion \
      --set QT_QUICK_CONTROLS_STYLE Fusion

    install -Dm644 usr/share/applications/Happ.desktop \
      $out/share/applications/Happ.desktop
    substituteInPlace $out/share/applications/Happ.desktop \
      --replace-fail "/opt/happ/bin/Happ" "$out/bin/happ"

    install -Dm644 usr/share/icons/hicolor/256x256/apps/happ.png \
      $out/share/icons/hicolor/256x256/apps/happ.png

    install -Dm644 usr/share/mime/packages/happ-mime.xml \
      $out/share/mime/packages/happ-mime.xml

    runHook postInstall
  '';

  meta = with lib; {
    description = "Happ — кроссплатформенный proxy-клиент на базе Xray-core";
    homepage = "https://www.happ.su/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
