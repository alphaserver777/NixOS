{
  programs.waybar = {
    enable = true;
    style = ./style.css;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 10;
        margin = "5";
        spacing = 10;
        modules-left = ["hyprland/workspaces" "disk" "memory" "cpu" "temperature" "battery" "custom/internet"];
        modules-center = ["hyprland/window"];
        modules-right = [ "tray" "idle_inhibitor" "custom/keyboard-layout" "backlight" "pulseaudio" "clock" ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          show-special = true;
          special-visible-only = true;
          all-outputs = false;
          format = "{icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            "6" = "";
            "7" = "";
            "8" = "";
            "9" = "";
            "magic" = "";
          };
          persistent-workspaces = {
            "*" = 8;
          };
        };

        "hyprland/window" = {
          icon = true;
          "icon-size" = 22;
          rewrite = {
            "(.*) — Mozilla Firefox" = "$1 - ";
            "(.*) - Visual Studio Code" = "$1 -  ";
            "(.*) - Discord" = "$1 -  ";
            "^$" = "";
          };
        };

        "custom/keyboard-layout" = {
          format = "{}";
          interval = 1; # раз в секунду обновлять
            exec = ''
            layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap')
          case "$layout" in
            *"Russian"*) echo "🇷🇺" ;;
            *"English"*) echo "🇺🇸" ;;
            *) echo "$layout" ;;
            esac
              '';
        };

# "custom/weather" = {
#   format = " {} ";
#   exec = "curl -s 'wttr.in/Krasnodar?format=%c%t&m'";
#   interval = 300;
#   class = "weather";
# };

        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };

        "backlight" = {
          interval = 2;
          format = " {percent}%";
          "on-click" = "brightnessctl set 10%+";
          "on-click-right" = "brightnessctl set 10%-";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-bluetooth = "{icon} {volume}% ";
          format-muted = " ";
          on-click = "amixer sset Master toggle";
          format-icons = {
            headphones = "";
            handsfree = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" "" "" ""];
          };
        };

        "custom/internet" = {
          exec = ./check_internet.sh;
          interval = 5;
          return-type = "json";
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          on-update = ''
            if [[ "$status" == "Discharging" && $capacity -le 20 ]]; then
              if [ ! -f /tmp/low_battery_notified ]; then
                notify-send -u critical "Low Battery" "Battery level is at ''${capacity}%!"
                  touch /tmp/low_battery_notified
                  fi
                  elif [[ "$status" == "Charging" || $capacity -gt 20 ]]; then
                  rm -f /tmp/low_battery_notified
                  fi
                  '';
          interval = 10;
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-alt = "{time} {icon}";
          format-icons = ["" "" "" "" ""];
          tooltip = true;
          "tooltip-format" = "{timeTo}";
        };

        "disk" = {
          interval = 30;
          format = " {percentage_used}%";
          "tooltip-format" = "{used} used out of {total} on \"{path}\" ({percentage_used}%)";
          "warning" = 80;
          "critical" = 95;
        };

        "memory" = {
          interval = 10;
          format = " {used}";
          "tooltip-format" = "{used}GiB used of {total}GiB ({percentage}%)";
          "warning" = 70;
          "critical" = 90;
        };

        "cpu" = {
          interval = 10;
          format = " {usage}%";
          "warning" = 70;
          "critical" = 90;
        };

        "temperature" = {
          interval = 10;
          "warning-temperature" = 60;
          "critical-temperature" = 80;
        };

        "clock" = {
          interval = 1;
          format = "{:%a %d:%b %H:%M}";
        };

        "tray" = {
          icon-size = 14;
          spacing = 0;
        };
      };
    };
  };
}
