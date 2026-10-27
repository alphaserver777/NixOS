{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper, wrapGAppsHook3
, gtk3, glib, libsecret, libayatana-appindicator, libGL, libepoxy, librsvg
, fontconfig, coreutils, bash, getent
}:

stdenv.mkDerivation rec {
  pname = "mantaray";
  version = "2.35.3";

  src = fetchurl {
    name = "MantaRay-Linux-amd64.deb";
    urls = [
      "https://storage.yandexcloud.net/ocean/MantaTech/linux/MantaRay-Linux-amd64.deb"
      "https://de2c580e-a390-4567-88f8-e7d8099376cf.selstorage.ru/MantaTech/linux/MantaRay-Linux-amd64.deb"
    ];
    hash = "sha256-JOYrgAXHlYqRHOJfnk4ixo54aK3Y7stA/iU5QXbf6wo=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper wrapGAppsHook3 ];
  buildInputs = [
    gtk3 glib libsecret libayatana-appindicator libGL libepoxy librsvg
    fontconfig stdenv.cc.cc.lib
  ];
  dontWrapGApps = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/opt" "$out/bin" "$out/libexec"
    cp -r opt/mantaray "$out/opt/"

    # Задача 042: обновление приложения выполняется через NixOS.
    # Установщик Debian и его привилегированная политика здесь не применяются.
    rm "$out/opt/mantaray/libexec/mantaray-linux-updater" \
      "$out/opt/mantaray/libexec/mantaray-recovery.py" \
      "$out/opt/mantaray/libexec/mantaray-recovery-trust.json" \
      "$out/opt/mantaray/libexec/mantaray-linux-package-format"

    install -Dm755 usr/bin/mantaray "$out/bin/mantaray"
    substituteInPlace "$out/bin/mantaray" \
      --replace-fail 'app=/opt/mantaray/mantaray' "app=$out/libexec/mantaray-gui" \
      --replace-fail '/usr/bin/sg' '/run/wrappers/bin/sg'

    cp -r usr/share "$out/"
    rm -r "$out/share/polkit-1"
    substituteInPlace "$out/share/applications/com.mantaray.vpn.desktop" \
      --replace-fail '/usr/bin/mantaray' "$out/bin/mantaray"
    runHook postInstall
  '';

  postFixup = ''
    makeWrapper "$out/opt/mantaray/mantaray" "$out/libexec/mantaray-gui" \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [ coreutils bash getent ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libGL libayatana-appindicator libsecret ]}
    wrapProgram "$out/bin/mantaray" \
      --prefix PATH : ${lib.makeBinPath [ coreutils bash getent ]}
  '';

  meta = {
    description = "MantaRay — приложение для подключения к VPN";
    homepage = "https://mantatech.ltd/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "mantaray";
  };
}
