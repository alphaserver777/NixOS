{ lib, stdenvNoCC, fetchurl, gzip, makeWrapper, kdePackages, qt6 }:
let
  qtPackages = with kdePackages; [ kirigami.unwrapped sonnet qtmultimedia qtimageformats kimageformats ];
  qmlPath = lib.concatStringsSep ":" (map (p: "${p}/${qt6.qtbase.qtQmlPrefix}") qtPackages);
  pluginPath = lib.concatStringsSep ":" (map (p: "${p}/${qt6.qtbase.qtPluginPrefix}") qtPackages);
  binary = fetchurl {
    url = "https://github.com/AvengeMedia/DankMaterialShell/releases/download/v1.6.2/dms-distropkg-amd64.gz";
    hash = "sha256-WdjZCk4Ii4uQEAIm/1yCus9GzmzoZJsbRqPspSUX0Nw=";
  };
in stdenvNoCC.mkDerivation {
  pname = "dms-shell";
  version = "1.6.2";
  src = fetchurl {
    url = "https://github.com/AvengeMedia/DankMaterialShell/releases/download/v1.6.2/dms-source.tar.gz";
    hash = "sha256-bjof9uAo0bNjoRnhii7WZNmbCpKHoBiYl+/la5CZ2yM=";
  };
  nativeBuildInputs = [ gzip makeWrapper ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share/quickshell/dms"
    gzip -dc ${binary} > "$out/bin/dms"
    chmod +x "$out/bin/dms"
    cp -rL quickshell/. "$out/share/quickshell/dms/"
    install -Dm644 assets/com.danklinux.dms.desktop "$out/share/applications/com.danklinux.dms.desktop"
    install -Dm644 core/assets/danklogo.svg "$out/share/icons/hicolor/scalable/apps/danklogo.svg"
    wrapProgram "$out/bin/dms" \
      --add-flags "-c $out/share/quickshell/dms" \
      --run 'export DMS_ORIG_NIXPKGS_QT6_QML_IMPORT_PATH="''${NIXPKGS_QT6_QML_IMPORT_PATH:-}"' \
      --run 'export DMS_ORIG_QT_PLUGIN_PATH="''${QT_PLUGIN_PATH:-}"' \
      --prefix NIXPKGS_QT6_QML_IMPORT_PATH : "${qmlPath}" \
      --prefix QT_PLUGIN_PATH : "${pluginPath}"
    runHook postInstall
  '';
  meta = {
    description = "DankMaterialShell: официальный выпуск с зависимостями NixOS";
    homepage = "https://danklinux.com";
    license = lib.licenses.mit;
    mainProgram = "dms";
    platforms = [ "x86_64-linux" ];
  };
}
