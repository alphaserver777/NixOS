{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper, wrapGAppsHook3
, alsa-lib, at-spi2-core, cairo, cups, dbus, expat, gdk-pixbuf, glib, gtk3
, libgbm, libGL, libnotify, nspr, nss, pango, openssl, tpm2-tss, systemd
, libusb1, libx11, libxcb, libxcomposite, libxdamage, libxext, libxfixes
, libxkbcommon, libxrandr, libsecret, zlib, bubblewrap, git, ripgrep
, xdg-utils, openssh
, qt6, libsForQt5
}:

# Задача 047: официальный выпуск Linux с Codex в приложении ChatGPT.
stdenv.mkDerivation rec {
  pname = "chatgpt-desktop";
  version = "26.1023.51421";

  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_amd64.deb";
    hash = "sha256-RITcK1T8CXi+sjuNjXF0lOTgtPvqsKh2c5EF5QtE3lo=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper wrapGAppsHook3 ];
  buildInputs = [
    alsa-lib at-spi2-core cairo cups dbus expat gdk-pixbuf glib gtk3
    libgbm libGL libnotify nspr nss pango openssl tpm2-tss systemd
    libusb1 libx11 libxcb libxcomposite libxdamage libxext libxfixes
    libxkbcommon libxrandr libsecret zlib stdenv.cc.cc.lib
    qt6.qtbase libsForQt5.qtbase
  ];
  # Эти библиотеки Chromium может загружать по имени во время работы.
  runtimeDependencies = [ libGL libgbm libsecret (lib.getLib systemd) ];
  # В комплекте есть альтернативные сборки модулей для Alpine/musl.
  # NixOS использует соседние варианты glibc; musl-файлы не запускаются.
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];
  dontWrapGApps = true;
  dontWrapQtApps = true;
  dontStrip = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/bin"
    mv usr/lib/chatgpt "$out/lib/chatgpt"
    mv usr/share "$out/share"
    for desktop in "$out"/share/applications/*.desktop; do
      sed -i \
        -e "s|^Exec=[^ ]*|Exec=$out/bin/chatgpt|" \
        -e 's/^Name=.*/Name=ChatGPT и Codex/' \
        "$desktop"
    done
    runHook postInstall
  '';

  postFixup = ''
    makeWrapper "$out/lib/chatgpt/codex-launcher" "$out/bin/chatgpt" \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [ bubblewrap git ripgrep xdg-utils openssh ]}
  '';

  meta = {
    description = "Официальное приложение ChatGPT и Codex с отдельным окном";
    homepage = "https://learn.chatgpt.com/docs/linux/linux-app";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "chatgpt";
  };
}
