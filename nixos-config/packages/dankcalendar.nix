{ lib, stdenvNoCC, fetchurl, gzip, makeWrapper, quickshell, kdePackages, qt6, pipewire, sound-theme-freedesktop, glib }:
let
  qtPackages = with kdePackages; [ kirigami.unwrapped sonnet qtmultimedia qtimageformats kimageformats ];
  qmlPath = lib.concatStringsSep ":" (map (p: "${p}/${qt6.qtbase.qtQmlPrefix}") qtPackages);
  pluginPath = lib.concatStringsSep ":" (map (p: "${p}/${qt6.qtbase.qtPluginPrefix}") qtPackages);
  icon = fetchurl {
    url = "https://github.com/AvengeMedia/dankcalendar/releases/download/v1.6.1/com.danklinux.dankcalendar.svg";
    hash = "sha256-zSa1Gd5cDpkBOaEmFr8Uqt5kSqOqOeYQaEA/UqcXiTM=";
  };
in stdenvNoCC.mkDerivation {
  pname = "dankcalendar";
  version = "1.6.1";
  src = fetchurl {
    url = "https://github.com/AvengeMedia/dankcalendar/releases/download/v1.6.1/dcal-linux-amd64.gz";
    hash = "sha256-5E7jXriLscgIagiu0C5tja1WL9eeb4uspjQfzKRX3d4=";
  };
  dontUnpack = true;
  dontBuild = true;
  nativeBuildInputs = [ gzip makeWrapper ];
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share/applications"
    gzip -dc "$src" > "$out/bin/dcal"
    chmod +x "$out/bin/dcal"
    install -Dm644 ${icon} "$out/share/icons/hicolor/scalable/apps/com.danklinux.dankcalendar.svg"
    cat > "$out/share/applications/com.danklinux.dankcalendar.desktop" <<EOF
    [Desktop Entry]
    Type=Application
    Name=DankCalendar
    Name[ru]=Календарь и задачи
    Exec=$out/bin/dcal open %u
    Icon=com.danklinux.dankcalendar
    Terminal=false
    Categories=Office;Calendar;Qt;
    MimeType=text/calendar;x-scheme-handler/webcal;
    StartupWMClass=com.danklinux.dankcalendar
    EOF
    wrapProgram "$out/bin/dcal" \
      --prefix PATH : "${lib.makeBinPath [ quickshell pipewire glib ]}" \
      --prefix XDG_DATA_DIRS : "${sound-theme-freedesktop}/share" \
      --prefix NIXPKGS_QT6_QML_IMPORT_PATH : "${qmlPath}" \
      --prefix QT_PLUGIN_PATH : "${pluginPath}"
    runHook postInstall
  '';
  meta = {
    description = "Локальный календарь и задачи с повторениями и звуковыми напоминаниями";
    homepage = "https://github.com/AvengeMedia/dankcalendar";
    license = lib.licenses.mit;
    mainProgram = "dcal";
    platforms = [ "x86_64-linux" ];
  };
}
