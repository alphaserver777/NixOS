
{
  programs.hyprlock = {
    enable = true;

    settings = {
      # фон
      background = {
        path = "/home/user/Pictures/wallpapers/lockscreen.png";
        blur_size = 8;
        blur_passes = 3;
        color = "rgba(30, 30, 46, 1.0)";
      };

      # аватар
      image = {
        path = "/home/user/Pictures/avatar.png";
        size = 128;
        border_color = "rgba(255, 255, 255, 1.0)";
        border_size = 4;
        position = "0, 80";
      };

      # время и дата
      label = [
        {
          text = "$TIME"; # Часы
          font_size = 64;
          font_family = "JetBrainsMono Nerd Font";
          color = "rgba(255, 255, 255, 1.0)";
          position = "0, -100";
          shadow = true;
        }
        {
          text = "$TIME:%A, %d"; # Дата
          font_size = 24;
          font_family = "JetBrainsMono Nerd Font";
          color = "rgba(208, 208, 208, 1.0)";
          position = "0, -50";
        }
      ];

      # поле ввода пароля
      input-field = {
        size = "200, 40";
        outline_thickness = 2;
        outline_color = "rgba(255, 255, 255, 1.0)";
        inner_color = "rgba(0, 0, 0, 0.5)";
        rounding = 12;
        position = "0, 180";
      };
    };
  };

  # Блокировка через 60 секунд простоя
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 60; # секунд
          on-timeout = "loginctl lock-session";
        }
      ];
    };
  };
}
