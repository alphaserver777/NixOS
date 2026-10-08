{ pkgs, ... }:
let
  dmsCenter = pkgs.runCommand "dms-centered-control" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    mkdir -p "$out"
    cp -r ${pkgs.dms-shell}/share/quickshell/dms/. "$out/"
    chmod -R u+w "$out"
    cp ${./CosmicCenter.qml} "$out/Modules/CosmicCenter.qml"
    python3 ${./dms-center-patch.py} "$out"
  '';
  noctalia = pkgs.writeShellApplication {
    name = "cosmic-noctalia";
    runtimeInputs = [ pkgs.noctalia pkgs.hyprland pkgs.systemd ];
    text = ''
      # Настройки сравнения не смешиваются с возможной прежней установкой.
      export NOCTALIA_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}/cosmic-desktop"
      export NOCTALIA_STATE_HOME="''${XDG_STATE_HOME:-$HOME/.local/state}/noctalia-trial"
      export NOCTALIA_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/noctalia-trial"
      exec noctalia "$@"
    '';
  };
  dms = pkgs.writeShellApplication {
    name = "cosmic-dms";
    runtimeInputs = [ pkgs.dms-shell pkgs.quickshell pkgs.dgop pkgs.systemd ];
    text = ''
      if [ "''${1:-}" = init ]; then
        settings_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell"
        mkdir -p "$settings_dir"
        if [ ! -e "$settings_dir/settings.json" ]; then
          install -m 600 ${./dms-settings.json} "$settings_dir/settings.json"
        fi
        exit 0
      fi
      export DMS_DISABLE_POLKIT=1
      export DMS_DISABLE_MATUGEN=1
      exec dms -c ${dmsCenter} "$@"
    '';
  };
  switcher = pkgs.writeShellApplication {
    name = "cosmic-shell";
    runtimeInputs = [ pkgs.python3 pkgs.systemd pkgs.walker pkgs.hyprpanel noctalia dms ];
    text = ''exec python3 ${./shell-switch.py} "$@"'';
  };
in {
  home.packages = [ noctalia dms switcher ];
  xdg.configFile."cosmic-desktop/noctalia/config.toml".source = ./noctalia.toml;

  # Home Manager запускает службы WantedBy при повторном применении.
  # Прежняя панель пропускает запуск, если выбрана другая оболочка.
  systemd.user.services.hyprpanel.Service.ExecCondition = "${switcher}/bin/cosmic-shell allow-original";

  systemd.user.services.cosmic-noctalia = {
    Unit = {
      Description = "Пробное оформление Noctalia";
      After = [ "graphical-session.target" "hyprpanel.service" ];
      PartOf = [ "graphical-session.target" ];
      Conflicts = [ "cosmic-dms.service" ];
    };
    Service = {
      ExecStartPre = "${noctalia}/bin/cosmic-noctalia config validate";
      ExecStart = "${noctalia}/bin/cosmic-noctalia";
      ExecStopPost = "${pkgs.systemd}/bin/systemctl --user --no-block start cosmic-shell-recover.service";
      Restart = "no";
      TimeoutStopSec = 5;
      KillMode = "control-group";
    };
  };
  systemd.user.services.cosmic-dms = {
    Unit = {
      Description = "Пробное оформление DankMaterialShell";
      After = [ "graphical-session.target" "hyprpanel.service" ];
      PartOf = [ "graphical-session.target" ];
      Conflicts = [ "cosmic-noctalia.service" ];
    };
    Service = {
      ExecStartPre = "${dms}/bin/cosmic-dms init";
      ExecStart = "${dms}/bin/cosmic-dms run --session";
      ExecStopPost = "${pkgs.systemd}/bin/systemctl --user --no-block start cosmic-shell-recover.service";
      Restart = "no";
      TimeoutStopSec = 5;
      KillMode = "control-group";
    };
  };
  systemd.user.services.cosmic-shell-recover = {
    Unit = {
      Description = "Возврат оформления после завершения оболочки";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${switcher}/bin/cosmic-shell recover";
    };
  };
  systemd.user.services.cosmic-shell-selection = {
    Unit = {
      Description = "Выбранное оформление рабочего стола";
      After = [ "graphical-session.target" "hyprpanel.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${switcher}/bin/cosmic-shell resume";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.desktopEntries = {
    cosmic-dms-trial = {
      name = "DankMaterialShell — попробовать";
      exec = "${switcher}/bin/cosmic-shell dms";
      icon = "preferences-desktop-theme";
      terminal = false;
      categories = [ "Settings" ];
    };
    cosmic-noctalia-trial = {
      name = "Noctalia — попробовать";
      exec = "${switcher}/bin/cosmic-shell noctalia";
      icon = "preferences-desktop-theme";
      terminal = false;
      categories = [ "Settings" ];
    };
    cosmic-shell-original = {
      name = "Вернуть прежнее оформление";
      exec = "${switcher}/bin/cosmic-shell original";
      icon = "preferences-desktop-theme";
      terminal = false;
      categories = [ "Settings" ];
    };
  };
}
