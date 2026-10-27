{ stdenv, lib, fetchurl, dpkg, autoPatchelfHook, makeWrapper
, openssl, glib, alsa-lib, libpulseaudio, libGL, libxkbcommon
, fontconfig, freetype, dbus, libdrm, mesa
, libgpg-error, libkrb5, e2fsprogs, qt6
, libx11, libxcb, libxext, libxrandr, libxrender
, libxfixes, libxi, libxtst, libxcomposite, libxdamage
, libxcursor, libxkbfile
, libxcb-util, libxcb-image, libxcb-keysyms
, libxcb-render-util, libxcb-wm, libxcb-cursor
}:

stdenv.mkDerivation rec {
  pname = "happ";
  version = "4.6.1";

  src = fetchurl {
    url = "https://github.com/Happ-proxy/happ-desktop/releases/download/${version}/Happ.linux.x64.deb";
    sha256 = "362538fabd97b6b77798a74f3e63a30a693a3300bcc05a2beca7d679948edbd5";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];

  buildInputs = [
    openssl glib alsa-lib libpulseaudio libGL libxkbcommon
    fontconfig freetype dbus libdrm mesa stdenv.cc.cc.lib
    libgpg-error libkrb5 e2fsprogs qt6.qtwayland
    libx11 libxcb libxext libxrandr libxrender
    libxfixes libxi libxtst libxcomposite libxdamage
    libxcursor libxkbfile
    libxcb-util libxcb-image libxcb-keysyms
    libxcb-render-util libxcb-wm libxcb-cursor
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
    # QT_STYLE_OVERRIDE=kvantum (например, от Stylix), Happ нужен Fusion-fallback,
    # иначе Main.qml не загружается. См. docs/tasks/003 про kvantum-баг upstream.
    makeWrapper $out/opt/happ/bin/Happ $out/bin/happ \
      --chdir $out/opt/happ/bin \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ openssl ]} \
      --set QT_STYLE_OVERRIDE Fusion \
      --set QT_QUICK_CONTROLS_STYLE Fusion

    # Задача 044: служба запускается NixOS, установщик Debian не выполняется.
    makeWrapper $out/opt/happ/bin/happd $out/bin/happd \
      --chdir $out/opt/happ/bin \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ openssl ]}

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
    mainProgram = "happ";
  };
}
