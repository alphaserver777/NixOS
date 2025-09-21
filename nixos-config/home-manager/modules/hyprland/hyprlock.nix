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
          path = toString ../../../wallpapers/space.png;

# path = "../../../wallpapers/bsod.png";
# Применяем эффекты
          blur_passes = 0.5;
          blur_size = 2;
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
          color = "rgba(205, 214, 244)";
          font_size = 80;
          font_family = "Maple Mono Bold";
          shadow_passes = 3;
          position = "0, -50";
          halign = "center";
          valign = "top";
        }
# Дата
        {
          monitor = "";
          text = ''cmd[update:1000] echo "- $(date +'%A, %B %d') -" '';
          color = "rgba(205, 214, 244)";
          font_size = 18;
          font_family = "Maple Mono";
          shadow_passes = 3;
          position = "0, -25";
          halign = "center";
          valign = "top";
        }
        ];

        input-field = [
        {
# Позиция поля ввода
          position = "0, 0";
# Размер
          size = "300, 60";
# Цвет текста
          font_color = "rgb(205, 214, 244)"; # Catppuccin Mocha 'Text'
# Цвет внутренней части
            inner_color = "rgb(49, 50, 68)"; # Catppuccin Mocha 'Surface2'
# Цвет границы
            outer_color = "rgb(186, 187, 241)"; # Catppuccin Mocha 'Lavender'
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
