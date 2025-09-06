{
  programs.waybar = {
    enable = true;
    style = ./style.css;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = ["hyprland/workspaces"];
        modules-center = ["hyprland/window"];
        modules-right = ["custom/keyboard-layout" "custom/weather" "pulseaudio" "custom/internet" "battery" "clock" "tray"];

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
            "*" = 9;
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

        "custom/weather" = {
          format = " {} ";
          exec = "curl -s 'wttr.in/Krasnodar?format=%c%t&m'";
          interval = 300;
          class = "weather";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-bluetooth = "{icon} {volume}% ";
          format-muted = "";
          format-icons = {
            "headphones" = "";
            "handsfree" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = ["" ""];
          };
          on-click = "pavucontrol";
        };

        "custom/internet" = {
          exec = "/home/admsys/GitOps/NixOs/nixos-config-reborn/home-manager/modules/waybar/test.sh";
          interval = 5;
          return-type = "json";
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 1;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-alt = "{time} {icon}";
          format-icons = ["" "" "" "" ""];
        };

        "clock" = {
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
