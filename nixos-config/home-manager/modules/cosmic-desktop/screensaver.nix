{ pkgs, lib, ... }:
let
  hyprsaver = pkgs.callPackage ../../../packages/hyprsaver.nix { };
  anurati = pkgs.callPackage ../../../packages/anurati.nix { };
  digits = pkgs.callPackage ../../../packages/cosmic-stencil.nix { };
  # Явный набор шрифтов не зависит от пользовательских правил подстановки.
  clockFonts = pkgs.writeText "cosmic-clock-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <dir>${anurati}/share/fonts</dir>
      <dir>${digits}/share/fonts</dir>
      <dir>${pkgs.orbitron}/share/fonts</dir>
      <dir>${pkgs.noto-fonts}/share/fonts</dir>
      <cachedir prefix="xdg">fontconfig</cachedir>
    </fontconfig>
  '';
  python = pkgs.python3.withPackages (p: [ p.pygobject3 p.pycairo ]);
  scripts = pkgs.runCommand "cosmic-screensaver-scripts" { } ''
    mkdir -p $out
    cp ${./screensaver.py} $out/screensaver.py
    cp ${./screensaver-control.py} $out/control.py
    cp ${./effects.py} $out/effects.py
    cp ${../display_selection.py} $out/display_selection.py
  '';
  clock = pkgs.writeShellApplication {
    name = "cosmic-screensaver-clock";
    runtimeInputs = [ pkgs.hyprland pkgs.procps ];
    text = ''
      export GDK_BACKEND=wayland
      # Часы рисуются без OpenGL: нет обрезания символов на втором экране.
      export GDK_GL=disable
      export GTK_THEME=Adwaita
      export FONTCONFIG_FILE=${clockFonts}
      export GI_TYPELIB_PATH="${lib.makeSearchPathOutput "out" "lib/girepository-1.0" [ pkgs.gtk3 pkgs.gtk-layer-shell pkgs.pango pkgs.gdk-pixbuf pkgs.atk pkgs.glib pkgs.cairo pkgs.harfbuzz pkgs.gobject-introspection ]}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
      exec ${pkgs.coreutils}/bin/env \
        LC_ALL=C \
        ${python}/bin/python3 ${scripts}/screensaver.py ${hyprsaver}/bin/hyprsaver
    '';
  };
  cursor = pkgs.writeShellApplication {
    name = "cosmic-screensaver-cursor";
    runtimeInputs = [ pkgs.hyprland pkgs.jq pkgs.coreutils ];
    text = ''
      state="''${RUNTIME_DIRECTORY:?}/cursor-state"
      case "''${1:-}" in
        hide)
          hyprctl -j getoption cursor:invisible \
            | jq -er '.int | select(. == 0 or . == 1)' > "$state"
          hyprctl keyword cursor:invisible 1
          ;;
        restore)
          if [[ -s "$state" ]]; then
            IFS= read -r previous < "$state"
            hyprctl keyword cursor:invisible "$previous"
            rm -f "$state"
          fi
          ;;
        *) exit 2 ;;
      esac
    '';
  };
  control = pkgs.writeShellApplication {
    name = "cosmic-screensaver";
    runtimeInputs = [ pkgs.systemd pkgs.zenity ];
    text = ''exec ${pkgs.python3}/bin/python3 ${scripts}/control.py "$@"'';
  };
in {
  home.packages = [ hyprsaver control anurati digits pkgs.orbitron ];
  fonts.fontconfig.enable = true;
  xdg.configFile."hypr/hyprsaver.toml".text = ''
    [general]
    shader = "cosmic-stars"
    palette = "cosmic"
    fps = 15
    synced = true

    [behavior]
    fade_in_ms = 800
    fade_out_ms = 300
    dismiss_on = ["key", "mouse_move", "mouse_click", "touch"]
    exclusive_keyboard = true

    [palettes.cosmic]
    a = [0.65, 0.67, 0.95]
    b = [0.14, 0.10, 0.02]
    c = [1.0, 1.0, 1.0]
    d = [0.0, 0.5, 0.0]
  '';
  # Четыре слоя вместо двадцати, спокойное движение звёзд.
  xdg.configFile."hypr/hyprsaver/shaders/cosmic-stars.frag".source =
    pkgs.runCommand "cosmic-stars.frag" { } ''
      sed -e 's/NUM_LAYERS = 20.0/NUM_LAYERS = 4.0/' \
          -e 's/SPEED = 0.36/SPEED = 0.22/' \
          ${hyprsaver}/share/hyprsaver/starfield.frag > $out
    '';
  xdg.configFile."hypr/hyprsaver/shaders/cosmic-aurora.frag".source = ./shaders/cosmic-aurora.frag;
  xdg.configFile."hypr/hyprsaver/shaders/cosmic-meteors.frag".source = ./shaders/cosmic-meteors.frag;
  xdg.configFile."hypr/hyprsaver/shaders/cosmic-constellations.frag".source = ./shaders/cosmic-constellations.frag;
  systemd.user.services.cosmic-screensaver = {
    Unit = {
      Description = "Космическая заставка с часами";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      RuntimeDirectory = "cosmic-screensaver";
      RuntimeDirectoryMode = "0700";
      ExecStartPre = "${cursor}/bin/cosmic-screensaver-cursor hide";
      ExecStart = "${clock}/bin/cosmic-screensaver-clock";
      # Выполняется также при ошибке запуска и принудительной остановке.
      ExecStopPost = "${cursor}/bin/cosmic-screensaver-cursor restore";
      Restart = "no";
      KillMode = "control-group";
      TimeoutStopSec = 3;
      RuntimeMaxSec = 180;
      Nice = 10;
      CPUQuota = "100%";
      MemoryMax = "512M";
    };
    # Службу запускает только hypridle или явная команда.
  };
  xdg.desktopEntries.cosmic-screensaver = {
    name = "Космическая заставка";
    exec = "${control}/bin/cosmic-screensaver start";
    icon = "preferences-desktop-screensaver";
    terminal = false;
    categories = [ "Utility" ];
  };
  xdg.desktopEntries.cosmic-screensaver-choice = {
    name = "Выбрать заставку";
    exec = "${control}/bin/cosmic-screensaver choose";
    icon = "preferences-desktop-screensaver";
    terminal = false;
    categories = [ "Settings" ];
  };
}
