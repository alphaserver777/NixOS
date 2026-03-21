{ lib, pkgs, ... }:
let
  theme = builtins.fromJSON (
    builtins.readFile "${pkgs.hyprpanel}/share/themes/tokyo_night_moon_split.json"
  );

  hyprpanelConfig = theme // {
    "bar.autoHide" = "never";
    "bar.bluetooth.label" = false;
    "bar.clock.format" = "%d %b %H:%M";
    "bar.clock.showIcon" = false;
    "bar.network.label" = true;
    "bar.notifications.hideCountWhenZero" = true;
    "bar.volume.label" = true;
    "bar.layouts" = {
      "0" = {
        left = [ "dashboard" "workspaces" "windowtitle" ];
        middle = [ "media" ];
        right = [ "volume" "network" "bluetooth" "battery" "systray" "clock" "notifications" ];
      };
      "1" = {
        left = [ "dashboard" "workspaces" "windowtitle" ];
        middle = [ "media" ];
        right = [ "volume" "network" "bluetooth" "battery" "systray" "clock" "notifications" ];
      };
    };
    "theme.bar.floating" = true;
    "theme.bar.margin_sides" = "0.8em";
    "theme.bar.margin_top" = "0.5em";
    "theme.bar.opacity" = 85;
    "theme.bar.transparent" = true;
    "theme.bar.buttons.monochrome" = false;
    "theme.bar.menus.opacity" = 95;
    "theme.font.name" = "JetBrainsMono Nerd Font";
  };

  nerdFont =
    if pkgs ? nerd-fonts.jetbrains-mono then
      pkgs.nerd-fonts.jetbrains-mono
    else
      pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
in
{
  programs.waybar.enable = lib.mkForce false;
  services.swaync.enable = lib.mkForce false;

  home.packages = [
    pkgs.hyprpanel
    nerdFont
  ];

  xdg.configFile."hyprpanel/config.json" = {
    text = builtins.toJSON hyprpanelConfig;
    onChange = "${pkgs.hyprpanel}/bin/hyprpanel r";
  };

  wayland.windowManager.hyprland.settings.exec-once = [
    "${pkgs.hyprpanel}/bin/hyprpanel"
  ];
}
