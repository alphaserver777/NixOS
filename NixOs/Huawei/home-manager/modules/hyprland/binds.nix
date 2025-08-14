{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland.settings = {
    # Основные бинды
    bind = [
      # Запуск терминала
      "$mainMod, T, exec, kitty"

      # Закрыть активное окно
      "$mainMod, Q, killactive,"

      # Выход из Hyprland
      "$mainMod, M, exit,"
 
      # Запуск лаунчера приложений
     "$mainMod, R, exec, wofi --show drun"

      # Переключение между рабочими столами
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"

      # Громкость
      ", XF86AudioRaiseVolume, exec, pamixer -i 5"
      ", XF86AudioLowerVolume, exec, pamixer -d 5"
      ", XF86AudioMute, exec, pamixer -t"

      # Яркость
      ", XF86MonBrightnessUp, exec, brightnessctl set +10%"
      ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
    ];
  };
}
