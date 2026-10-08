{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        before_sleep_cmd = "cosmic-screensaver stop; loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        # Режим «Кофе» DMS предотвращает все действия по таймеру простоя.
        ignore_wayland_inhibit = false;
        # Не переходить в сон до подтверждения блокировки.
        inhibit_sleep = 3;
        # Блокировка живёт отдельно от hypridle и переживает его перезапуск.
        lock_cmd = "cosmic-screensaver stop; pidof hyprlock || hyprctl dispatch exec hyprlock";
      };

      listener = [
        {
          timeout = 120;
          on-timeout = "cosmic-screensaver start";
          on-resume = "cosmic-screensaver stop";
        }
        {
          timeout = 180;
          on-timeout = "brightnessctl -s set 30";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 300;
          on-timeout = "cosmic-screensaver stop; loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = "cosmic-screensaver stop; hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 1200;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
