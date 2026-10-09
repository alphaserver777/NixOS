{ lib, pkgs, hostname, ... }: {
  wayland.windowManager.hyprland = {
    plugins = [ pkgs.hyprlandPlugins.hyprspace ];
    enable = true;
    configType = "hyprlang";
    systemd.enable = true;
    settings = {
      env = [
        # Hint Electron apps to use Wayland
        "NIXOS_OZONE_WL,1"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_QPA_PLATFORM,wayland"
        "XDG_SCREENSHOTS_DIR,$HOME/screens"
      ];

      monitor =
        if hostname == "main" then [
          "HDMI-A-1,1920x1080@144.00Hz,0x0,1"
          "DVI-D-1,1920x1080@60.00Hz,1920x0,1"
          "DP-1,1440x900@59.89Hz,0x-900,1"
        ] else if hostname == "x-disk" then [
          "HDMI-A-3,1920x1080@60.00Hz,0x0,1"
          "DP-2,1920x1080@60.00Hz,1920x0,1"
        ] else ",1920x1080@60,auto,1";
      "$mainMod" = "SUPER";
      "$terminal" = "alacritty";
      "$fileManager" = "doublecmd --client --no-splash";
      "$menu" = "walker";

      exec-once = [
        # Историю текста и изображений ведёт Elephant; старый архив сохранён.
        # Предсоздаём рабочие столы 1..9, чтобы раскладка Expo была стабильной
        "sh -lc \"cur=$(hyprctl activeworkspace -j | jq -r .id 2>/dev/null || echo 1); for i in $(seq 1 9); do hyprctl dispatch workspace $i; done; hyprctl dispatch workspace $cur\""
      ] ++ lib.optionals (hostname == "x-disk") [
        # При отсутствии DP-2 все рабочие столы остаются на HDMI-A-3.
        ''sh -lc 'sleep 1; target=HDMI-A-3; if hyprctl monitors | grep -q "^Monitor DP-2 "; then target=DP-2; fi; for i in 6 7 8 9; do hyprctl dispatch moveworkspacetomonitor "$i $target"; done' ''
      ];

      general = {
        gaps_in = 6;
        gaps_out = 10;

        border_size = 2;

        "col.active_border" = "rgba(89b4faff) rgba(cba6f7ff) 45deg";
        "col.inactive_border" = "rgba(30364cff)";

        resize_on_border = true;

        allow_tearing = false;
        layout = "master";
      };

      decoration = {
        rounding = 14;

        active_opacity = 1.0;
        inactive_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 18;
          render_power = 3;
          color = "rgba(00000055)";
        };

        blur = {
          enabled = false;
          size = 8;
          passes = 4;
          vibrancy = 0.1696;
        };
      };

      xwayland = {
        force_zero_scaling = true;
      };

      animations = {
        enabled = true;
        bezier = [
          "cosmic, 0.16, 1, 0.3, 1"
          "cosmic-close, 0.4, 0, 1, 1"
          "cosmic-glide, 0.22, 1, 0.36, 1"
        ];
        animation = [
          "windowsIn, 1, 3.2, cosmic, popin 94%"
          "windowsOut, 1, 2, cosmic-close, popin 97%"
          "windowsMove, 1, 3.5, cosmic-glide"
          "border, 1, 2.5, cosmic"
          "fade, 1, 2, cosmic"
          "workspaces, 1, 3.5, cosmic-glide, slide"
          "specialWorkspace, 1, 3, cosmic, slidevert"
          "layersIn, 1, 2.5, cosmic, slide top"
          "layersOut, 1, 1.5, cosmic-close, fade"
        ];
      };

      plugin.overview = {
        panelColor = "rgba(151824ff)";
        panelBorderColor = "rgba(89b4faff)";
        workspaceActiveBackground = "rgba(242c40ff)";
        workspaceInactiveBackground = "rgba(151824ff)";
        workspaceActiveBorder = "rgba(cba6f7ff)";
        panelBorderWidth = 1;
        workspaceBorderSize = 2;
        workspaceMargin = 8;
        disableBlur = true;
        centerAligned = true;
        showEmptyWorkspace = true;
        showNewWorkspace = true;
        autoDrag = true;
      };

      input = {
        kb_layout = "us,ru";
        kb_variant = ","; # пустая строка для обеих раскладок
        kb_options = "grp:caps_toggle";
      };

      device = [{
        name = "wacom-bamboo-one-s-pen";
        output = "HDMI-A-1";
      }];

      gesture = [ "3, horizontal, workspace" ];
      gestures = {
        workspace_swipe_invert = false;
        workspace_swipe_forever = true;
      };

      dwindle = {
        preserve_split = true;
      };

      master = {
        new_status = "slave";
        new_on_top = true;
        mfact = 0.5;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      windowrule = [
        "match:class (mpv|imv|showmethekey-gtk), float on"
        "match:class showmethekey-gtk, move 990 60, size 900 170, pin on, no_initial_focus on"
        "match:class google-chrome, workspace 1"
        "match:class Alacritty, workspace 2"
        "match:class obsidian, workspace 3"
        "match:class zathura, workspace 3"
        "match:class ^(code(-oss)?|code-url-handler|vscode|VSCodium|Code)$, workspace 4"
        "match:class org.telegram.desktop, workspace 5"
        "match:class qemu, workspace 6"
        "match:class .*, suppress_event maximize"
        "match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false, no_focus on"
        "match:class xwaylandvideobridge, opacity 0.0 override, no_anim on, no_initial_focus on, max_size 1 1, no_blur on, no_focus on"
      ];

      workspace =
        if hostname == "main" then [
          "1, monitor:HDMI-A-1"
          "2, monitor:HDMI-A-1"
          "3, monitor:HDMI-A-1"
          "4, monitor:HDMI-A-1"
          "5, monitor:HDMI-A-1"
          "6, monitor:DVI-D-1"
          "7, monitor:DVI-D-1"
          "8, monitor:DVI-D-1"
          "9, monitor:DVI-D-1"
          "10, monitor:DP-1"
          "f[1], gapsout:0, gapsin:0"
        ] else if hostname == "x-disk" then [
          "1, monitor:HDMI-A-3"
          "2, monitor:HDMI-A-3"
          "3, monitor:HDMI-A-3"
          "4, monitor:HDMI-A-3"
          "5, monitor:HDMI-A-3"
          "6, monitor:DP-2"
          "7, monitor:DP-2"
          "8, monitor:DP-2"
          "9, monitor:DP-2"
          "f[1], gapsout:0, gapsin:0"
        ] else [
          "f[1], gapsout:0, gapsin:0"
        ];
    };
  };
}
