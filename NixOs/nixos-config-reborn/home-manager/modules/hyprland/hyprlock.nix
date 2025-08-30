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
# Устанавливаем изображение
          path = "/home/admsys/wallpapers/otherWallpaper/gruvbox/forest_road.jpg";
# Применяем эффекты
          blur_passes = 4;
          blur_size = 10;
          contrast = 0.5;
          brightness = 0.5;
          vibrancy = 0.5;
        }
        ];

# Настройки для текстовых элементов (Time и Date)
        label = [
# Время
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date +'%k:%M')"'';
          color = "rgba(235, 219, 178, 0.9)";
          font_size = 115;
          font_family = "Maple Mono Bold";
          shadow_passes = 3;
          position = "0, -25";
          halign = "center";
          valign = "top";
        }
# Дата
        {
          monitor = "";
          text = ''cmd[update:1000] echo "- $(date +'%A, %B %d') -" '';
          color = "rgba(235, 219, 178, 0.9)";
          font_size = 18;
          font_family = "Maple Mono";
          shadow_passes = 3;
          position = "0, -25";
          halign = "center";
          valign = "top";
        }
        ];

# Поле для ввода пароля (отдельный элемент)
        input-field = [
        {
# Позиция поля ввода
          position = "0, 0";
# Размер
          size = "300, 60";
# Цвет текста
          font_color = "rgb(00ff00)";
# Цвет внутренней части
          inner_color = "rgb(1a1a1a)";
# Цвет границы
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
