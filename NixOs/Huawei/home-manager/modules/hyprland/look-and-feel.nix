{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland.settings = {
    decoration = {
      #rounding = 8;
      #blur = true;
      # blur_size = 3;
      # blur_passes = 3;
      # drop_shadow = true;
      # shadow_range = 4;
      # shadow_render_power = 3;
    };

    animations = {
      enabled = true;
      animation = [
        "windows, 1, 7, default"
        "workspaces, 1, 4, default"
      ];
    };
  };
}
