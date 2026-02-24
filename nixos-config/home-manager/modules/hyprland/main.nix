{ lib, pkgs, hostname, ... }: {
  wayland.windowManager.hyprland = {
    plugins = [ pkgs.hyprlandPlugins.hyprexpo ];
    enable = true;
    extraConfig = ''
      plugin = ${pkgs.hyprlandPlugins.hyprexpo}/lib/libhyprexpo.so
    '';
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
          "HDMI-A-1,1920x1080@144.00Hz,0x0,1.25"
          "DVI-D-1,1920x1080@60.00Hz,1536x0,1.25"
        ] else ",1920x1080@60,auto,1.25";
      "$mainMod" = "SUPER";
      "$terminal" = "alacritty";
      "$fileManager" = "$terminal -e sh -c 'ranger'";
      "$menu" = "wofi";

      exec-once = [
        "waybar"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        # Предсоздаём рабочие столы 1..9, чтобы раскладка Expo была стабильной
        "sh -lc \"cur=$(hyprctl activeworkspace -j | jq -r .id 2>/dev/null || echo 1); for i in $(seq 1 9); do hyprctl dispatch workspace $i; done; hyprctl dispatch workspace $cur\""
      ];

      general = {
        gaps_in = 0;
        gaps_out = 0;

        border_size = 5;

        "col.active_border" = "rgba(89b4faff) rgba(f5c2e7ff) 45deg";
        "col.inactive_border" = "rgba(3c3836ff)";

        resize_on_border = true;

        allow_tearing = false;
        layout = "master";
      };

      decoration = {
        rounding = 10;

        active_opacity = 0.85;
        inactive_opacity = 0.85;

        shadow = {
          enabled = false;
        };

        blur = {
          enabled = true;
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

      gestures = {
        workspace_swipe = true;
        workspace_swipe_invert = false;
        workspace_swipe_forever = true;
      };

      dwindle = {
        pseudotile = true;
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

      windowrulev2 = [
        "float,class:^(flameshot)$"
        "pin,class:^(flameshot)$"
        "noborder,class:^(flameshot)$"

        "bordersize 0, floating:0, onworkspace:w[t1]"

        "float,class:(mpv)|(imv)|(showmethekey-gtk)"
        "move 990 60,size 900 170,pin,noinitialfocus,class:(showmethekey-gtk)"
        # "noborder,nofocus,class:(showmethekey-gtk)"
        "workspace 1,class:(google-chrome)"
        "workspace 2,class:(Alacritty)"
        "workspace 3,class:(obsidian)"
        "workspace 3,class:(zathura)"
        "workspace 4,class:^(code(-oss)?|code-url-handler|vscode|VSCodium|Code)$"
        "workspace 5,class:(org.telegram.desktop)"
        "workspace 6,class:(qemu)"

        "suppressevent maximize, class:.*"
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

        "opacity 0.0 override, class:^(xwaylandvideobridge)$"
        "noanim, class:^(xwaylandvideobridge)$"
        "noinitialfocus, class:^(xwaylandvideobridge)$"
        "maxsize 1 1, class:^(xwaylandvideobridge)$"
        "noblur, class:^(xwaylandvideobridge)$"
        "nofocus, class:^(xwaylandvideobridge)$"
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
          "w[tv1], gapsout:0, gapsin:0"
          "f[1], gapsout:0, gapsin:0"
        ] else [
          "w[tv1], gapsout:0, gapsin:0"
          "f[1], gapsout:0, gapsin:0"
        ];
    };
  };
}
