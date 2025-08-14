{ config, pkgs, ... }:

{
  # Включаем Hyprland и настраиваем его
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Переменные (горячие клавиши)
      "$mainMod" = "SUPER";

      #Клавиатура - переключение на Капс
      input = {
        kb_layout = "us,ru";
        kb_options = "grp:caps_toggle";
      };
    };
  };
}
