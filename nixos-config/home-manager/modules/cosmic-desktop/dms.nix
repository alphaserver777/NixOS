{ pkgs, ... }:
let
  dmsPackage = pkgs.callPackage ../../../packages/dms-shell-1-6-2.nix { };
  calendarPackage = pkgs.callPackage ../../../packages/dankcalendar.nix { };
  sandsSource = pkgs.fetchFromGitHub {
    owner = "lung595";
    repo = "Sands";
    rev = "b3760d9d438e06d37b136a8c2f9c87fed73de279";
    hash = "sha256:1b8h56gvk4rnzln7ym0xg8sh6cx0bizf4wc3g2jbx39iaiys3xz2";
  };
  sands = pkgs.runCommand "sands-1.4.3-dms-1.6" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    mkdir -p "$out"
    cp -r ${sandsSource}/. "$out/"
    chmod -R u+w "$out"
    python3 ${./sands-adapt.py} "$out" ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo
  '';
  dmsCenter = pkgs.runCommand "dms-centered-control" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    mkdir -p "$out"
    cp -r ${dmsPackage}/share/quickshell/dms/. "$out/"
    chmod -R u+w "$out"
    cp ${./CosmicCenter.qml} "$out/Modules/CosmicCenter.qml"
    cp ${./KeyboardLayoutOSD.qml} "$out/Modules/KeyboardLayoutOSD.qml"
    cp -r ${./flags} "$out/assets/flags"
    cp ${./ClipboardDetail.qml} "$out/Modals/Clipboard/ClipboardDetail.qml"
    python3 ${./dms-center-patch.py} "$out"
  '';
  dms = pkgs.writeShellApplication {
    name = "cosmic-dms";
    runtimeInputs = [ dmsPackage calendarPackage pkgs.jq pkgs.quickshell pkgs.dgop pkgs.systemd pkgs.python3 pkgs.pipewire pkgs.libnotify pkgs.glib ];
    text = ''
      if [ "''${1:-}" = init ]; then
        settings_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell"
        mkdir -p "$settings_dir"
        if [ ! -e "$settings_dir/settings.json" ]; then
          install -m 600 ${./dms-settings.json} "$settings_dir/settings.json"
        fi
        python3 ${./dms-initialize.py}
        exit 0
      fi
      export DMS_DISABLE_POLKIT=1
      export DMS_DISABLE_MATUGEN=1
      # Сохраняем команды горячих клавиш после изменения CLI.
      if [ "''${1:-}" = ipc ] && [ -n "''${2:-}" ] && [ "''${2:-}" != call ] && [ "''${2:-}" != --help ] && [ "''${2:-}" != -h ]; then
        shift
        set -- ipc call "$@"
      fi
      exec dms -c ${dmsCenter} "$@"
    '';
  };
  lock = pkgs.writeShellApplication {
    name = "cosmic-lock";
    runtimeInputs = [ pkgs.systemd pkgs.coreutils ];
    text = ''
      session="$(loginctl show-user "$(id -u)" --property=Display --value)"
      if [ -z "$session" ]; then
        echo "Не найден графический сеанс для блокировки" >&2
        exit 1
      fi
      exec loginctl lock-session "$session"
    '';
  };
in {
  home.packages = [ dms lock ];
  xdg.configFile."DankMaterialShell/plugins/Sands".source = sands;

  # Задача 016: выбранная панель запускается напрямую при каждом входе.
  # Готовность интерфейса не ограничивается коротким ожиданием переключателя.
  systemd.user.services.cosmic-dms = {
    Unit = {
      Description = "Рабочий стол DankMaterialShell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };
    Service = {
      ExecStartPre = "${dms}/bin/cosmic-dms init";
      ExecStart = "${dms}/bin/cosmic-dms run --session";
      Restart = "on-failure";
      RestartSec = 3;
      TimeoutStopSec = 10;
      KillMode = "control-group";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
