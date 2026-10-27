{ lib, hostname, ... }:
{
  # Задача 040: проверка смещения аппаратного курсора nouveau на main.
  # Координаты ввода сохраняются; курсор рисуется вместе с изображением.
  wayland.windowManager.hyprland.settings.cursor = lib.mkIf (hostname == "main") {
    no_hardware_cursors = 1;
  };
}
