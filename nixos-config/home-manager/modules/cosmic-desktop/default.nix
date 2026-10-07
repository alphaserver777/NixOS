{ pkgs, ... }:
let
  python = pkgs.python3.withPackages (p: [ p.pillow ]);
  wallpaper = ../../../wallpapers/cosmic-panorama.png;
  panorama = pkgs.writeShellApplication {
    name = "cosmic-panorama";
    runtimeInputs = [ python pkgs.hyprland ];
    text = ''exec python ${./panorama.py} --image ${wallpaper} "$@"'';
  };
  mode = pkgs.writeShellApplication {
    name = "cosmic-mode";
    runtimeInputs = [ pkgs.python3 pkgs.hyprland pkgs.walker pkgs.libnotify ];
    text = ''exec python3 ${./mode.py} "$@"'';
  };
  sessionUnit = description: {
    Description = description;
    After = [ "graphical-session.target" ];
    PartOf = [ "graphical-session.target" ];
  };
in {
  home.packages = [ pkgs.walker pkgs.elephant panorama mode ];

  # Панорамой управляет один процесс; обычный фон остаётся запасным.
  stylix.targets.hyprpaper.enable = false;
  services.hyprpaper.settings = {
    splash = false;
    wallpaper = [{ monitor = ""; path = "${wallpaper}"; }];
  };

  systemd.user.services.cosmic-panorama = {
    Unit = (sessionUnit "Панорамные обои") // {
      After = [ "graphical-session.target" "hyprpaper.service" ];
      Requires = [ "hyprpaper.service" ];
    };
    Service = {
      ExecStart = "${panorama}/bin/cosmic-panorama";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  systemd.user.services.elephant = {
    Unit = sessionUnit "Служба общего поиска";
    Service = {
      ExecStart = "${pkgs.elephant}/bin/elephant";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  systemd.user.services.walker = {
    Unit = (sessionUnit "Общий поиск") // { After = [ "graphical-session.target" "elephant.service" ]; };
    Service = {
      ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile = {
    "walker/config.toml".source = ./walker.toml;
    "walker/themes/cosmic/style.css".source = ./style.css;
    "walker/themes/cosmic/layout.xml".source = ./layout.xml;
    "elephant/elephant.toml".text = ''
      terminal_cmd = "alacritty"
      ignored_providers = ["1password", "archlinuxpkgs", "bitwarden", "bluetooth", "bookmarks", "dnfpackages", "niriactions", "nirisessions", "snippets", "todo", "unicode"]
    '';
    "elephant/files.toml".text = ''
      ignored_dirs = ["/node_modules(/|$)", "/target(/|$)", "/.git(/|$)", "/.cache(/|$)", "/.local/state(/|$)"]
      watch = false
    '';
  };
  xdg.desktopEntries = builtins.listToAttrs (map (entry: {
    name = "cosmic-${entry.key}";
    value = {
      name = "Режим «${entry.label}»";
      exec = "${mode}/bin/cosmic-mode ${entry.key}";
      icon = entry.icon;
      terminal = false;
      categories = [ "Utility" ];
    };
  }) [
    { key = "work"; label = "Работа"; icon = "applications-development"; }
    { key = "video"; label = "Видео"; icon = "video-display"; }
    { key = "show"; label = "Показ"; icon = "preferences-desktop-display"; }
    { key = "normal"; label = "Обычный"; icon = "user-desktop"; }
  ]);
}
