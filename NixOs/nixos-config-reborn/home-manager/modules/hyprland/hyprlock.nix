{
  programs = {
    hyprlock = {
      enable = true;
      settings = {
# Общие настройки поведения
        general = {
# Скрываем курсор, чтобы не отвлекал
          hide_cursor = true;
        };

# Настройки фона
        background = [
        {
# Делаем скриншот текущего рабочего стола и затемняем его
          path = "/home/admsys/wallpapers/otherWallpaper/gruvbox/forest_road.jpg";
          blur_passes = 4;
          blur_size = 10;
          contrast = 0.5;
          brightness = 0.5;
          vibrancy = 0.5;
        }
        ];

# Поле для ввода пароля
        input-field = [
        {
# Позиция поля ввода
          position = "0, 0";
# Размер
          size = "300, 60";
# Цвет текста (зеленый)
          font_color = "rgb(00ff00)";
# Цвет внутренней части поля (темный)
          inner_color = "rgb(1a1a1a)";
# Цвет границы (зеленый)
          outer_color = "rgb(00ff00)";
# Толщина границы
          outline_thickness = 2;
# Текст-заполнитель
          placeholder_text = "ACCESS CODE";
# Анимация
          fade_on_empty = false;
        }
        ];
      };
    };
  };
}
