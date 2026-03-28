{ lib, pkgs, hostname, user, ... }:

{
  imports = [
    ./modules/alacritty.nix
    ./modules/atuin.nix
    ./modules/eza.nix
    ./modules/fzf.nix
    ./modules/git.nix
    ./modules/google-chrome.nix
    ./modules/hyprpanel.nix
    ./modules/nvim-config
    ./modules/starship.nix
    ./modules/stylix.nix
    ./modules/tmux.nix
    ./modules/wofi
    ./modules/zoxide.nix
    ./modules/zsh.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    sessionVariables = {
      QT_SCREEN_SCALE_FACTORS = "1;1";
    };
    packages = with pkgs; [
      brightnessctl
      cliphist
      jq
      playerctl
      ranger
      wl-clipboard
    ];
  };

  wayland.windowManager.hyprland = {
    plugins = [ pkgs.hyprlandPlugins.hyprexpo ];
    enable = true;
    extraConfig = ''
      plugin = ${pkgs.hyprlandPlugins.hyprexpo}/lib/libhyprexpo.so
    '';
    systemd.enable = true;
    settings = {
      env = [
        "NIXOS_OZONE_WL,1"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_QPA_PLATFORM,wayland"
      ];

      monitor =
        if hostname == "main" then [
          "HDMI-A-1,1920x1080@144.00Hz,0x0,1"
          "DVI-D-1,1920x1080@60.00Hz,1536x0,1"
        ] else ",preferred,auto,1";

      "$mainMod" = "SUPER";
      "$terminal" = "alacritty";
      "$fileManager" = "$terminal -e ranger";
      "$menu" = "wofi";

      exec-once = [
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 4;
        "col.active_border" = "rgba(89b4faff) rgba(f5c2e7ff) 45deg";
        "col.inactive_border" = "rgba(3c3836ff)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "master";
      };

      decoration = {
        rounding = 10;
        active_opacity = 0.92;
        inactive_opacity = 0.88;
        shadow.enabled = false;
        blur = {
          enabled = true;
          size = 8;
          passes = 4;
          vibrancy = 0.1696;
        };
      };

      animations.enabled = true;
      xwayland.force_zero_scaling = true;

      input = {
        kb_layout = "us,ru";
        kb_variant = ",";
        kb_options = "grp:caps_toggle";
      };

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

      bind = [
        "$mainMod, T, exec, $terminal"
        "$mainMod, Q, killactive,"
        "$mainMod CTRL, M, exit,"
        "$mainMod, R, exec, $menu --show drun"
        "$mainMod SHIFT, R, exec, $fileManager"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, B, exec, google-chrome-stable --ozone-platform=wayland --disable-gpu"
        "$mainMod, F, togglefloating,"
        "$mainMod, P, pin,"
        "$mainMod, J, togglesplit,"
        "$mainMod, TAB, exec, hyprctl dispatch hyprexpo:expo toggle"
        "$mainMod, V, exec, cliphist list | $menu --dmenu | cliphist decode | wl-copy"

        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        "$mainMod SHIFT, left, swapwindow, l"
        "$mainMod SHIFT, right, swapwindow, r"
        "$mainMod SHIFT, up, swapwindow, u"
        "$mainMod SHIFT, down, swapwindow, d"

        "$mainMod CTRL, left, resizeactive, -60 0"
        "$mainMod CTRL, right, resizeactive, 60 0"
        "$mainMod CTRL, up, resizeactive, 0 -60"
        "$mainMod CTRL, down, resizeactive, 0 60"

        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"

        "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
        "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
        "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
        "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
        "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
        "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
        "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
        "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
        "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        "$mainMod, bracketright, exec, brightnessctl s 10%+"
        "$mainMod, bracketleft, exec, brightnessctl s 10%-"
      ];

      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      windowrulev2 = [
        "workspace 1,class:(google-chrome)"
        "float,class:(mpv)"
        "suppressevent maximize, class:.*"
      ];

      workspace = [
        "w[tv1], gapsout:0, gapsin:0"
        "f[1], gapsout:0, gapsin:0"
      ];
    };
  };
}
