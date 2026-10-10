{ pkgs, ... }:
let
  wallpaper = ../../../wallpapers/space.png;
  mode = pkgs.writeShellApplication {
    name = "cosmic-mode";
    runtimeInputs = [ pkgs.python3 pkgs.hyprland pkgs.zenity pkgs.libnotify ];
    text = ''exec python3 ${./mode.py} "$@"'';
  };
in {
  imports = [ ./screensaver.nix ./dms.nix ./calendar.nix ];
  home.packages = [ mode ];

  # Прежние обои с космонавтом целиком на каждом экране.
  stylix.targets.hyprpaper.enable = false;
  services.hyprpaper.settings = {
    splash = false;
    wallpaper = [{ monitor = ""; path = "${wallpaper}"; }];
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
