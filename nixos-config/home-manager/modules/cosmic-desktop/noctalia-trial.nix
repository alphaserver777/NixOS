{ pkgs, ... }:
let
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
  switcher = pkgs.writeShellApplication {
    name = "cosmic-shell";
    runtimeInputs = [ pkgs.python3 pkgs.systemd pkgs.walker pkgs.hyprpanel noctalia ];
    text = ''exec python3 ${./shell-switch.py} "$@"'';
  };
in {
  home.packages = [ noctalia switcher ];
  xdg.configFile."cosmic-desktop/noctalia/config.toml".source = ./noctalia.toml;

  systemd.user.services.cosmic-noctalia = {
    Unit = {
      Description = "Пробное оформление Noctalia";
      After = [ "graphical-session.target" "hyprpanel.service" ];
      PartOf = [ "graphical-session.target" ];
      Conflicts = [ "hyprpanel.service" ];
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
  systemd.user.services.cosmic-shell-recover = {
    Unit = {
      Description = "Возврат панели после завершения Noctalia";
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
