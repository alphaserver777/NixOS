{ lib, pkgs, ... }:
let
  theme = builtins.fromJSON (
    builtins.readFile "${pkgs.hyprpanel}/share/themes/tokyo_night_moon_split.json"
  );

  customModules = {
    "custom/keyboard-flags" = {
      label = "{}";
      tooltip = "Keyboard Layout";
      interval = 1;
      execute = ''
        layout=$(hyprctl devices -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.keyboards[] | select(.main == true) | .active_keymap' 2>/dev/null)
        case "$layout" in
          *Russian*) echo "🇷🇺" ;;
          *English*) echo "🇺🇸" ;;
          *) echo "🌐" ;;
        esac
      '';
    };
  };

  hyprpanelConfig = theme // {
    "bar.autoHide" = "never";
    "bar.clock.format" = "%d %b %H:%M";
    "bar.clock.showIcon" = false;
    "bar.bluetooth.label" = false;
    "bar.network.label" = true;
    "bar.volume.label" = true;
    "bar.customModules.kbLayout.label" = true;
    "bar.customModules.kbLayout.labelType" = "code";
    "bar.customModules.kbLayout.icon" = "󰌌";
    "bar.notifications.hideCountWhenZero" = true;
    "bar.launcher.autoDetectIcon" = false;
    "bar.launcher.icon" = "";
    "bar.workspaces.show_numbered" = true;
    "bar.workspaces.showWsIcons" = true;
    "bar.workspaces.show_icons" = false;
    "bar.workspaces.monitorSpecific" = false;
    "bar.workspaces.showAllActive" = true;
    "bar.workspaces.workspaces" = 9;
    "bar.workspaces.workspaceIconMap" = {
      "1" = "";
      "2" = "";
      "3" = "";
      "4" = "";
      "5" = "";
      "6" = "";
      "7" = "";
      "8" = "";
      "9" = "";
      "10" = "";
    };

    "menus.dashboard.shortcuts.left.shortcut1.command" = "code";
    "menus.dashboard.shortcuts.left.shortcut1.icon" = "";
    "menus.dashboard.shortcuts.left.shortcut1.tooltip" = "VS Code";
    "menus.dashboard.shortcuts.left.shortcut2.command" = "keepassxc";
    "menus.dashboard.shortcuts.left.shortcut2.icon" = "";
    "menus.dashboard.shortcuts.left.shortcut2.tooltip" = "KeePassXC";
    "menus.dashboard.shortcuts.left.shortcut3.command" = "obsidian";
    "menus.dashboard.shortcuts.left.shortcut3.icon" = "󰎚";
    "menus.dashboard.shortcuts.left.shortcut3.tooltip" = "Obsidian";
    "menus.dashboard.shortcuts.left.shortcut4.command" = "amnezia-vpn";
    "menus.dashboard.shortcuts.left.shortcut4.icon" = "󰖂";
    "menus.dashboard.shortcuts.left.shortcut4.tooltip" = "AmneziaVPN";
    "menus.dashboard.shortcuts.right.shortcut1.command" = "obs";
    "menus.dashboard.shortcuts.right.shortcut1.icon" = "󰐻";
    "menus.dashboard.shortcuts.right.shortcut1.tooltip" = "OBS Studio";

    "bar.layouts" = {
      "0" = {
        left = [ "dashboard" "workspaces" ];
        middle = [ "windowtitle" ];
        right = [ "systray" "custom/keyboard-flags" "network" "bluetooth" "volume" "battery" "clock" "notifications" ];
      };
      "1" = {
        left = [ "dashboard" "workspaces" ];
        middle = [ "windowtitle" ];
        right = [ "systray" "custom/keyboard-flags" "network" "bluetooth" "volume" "battery" "clock" "notifications" ];
      };
    };

    "theme.font.name" = "JetBrainsMono Nerd Font";
    "theme.font.size" = "0.8rem";
    "theme.font.weight" = 700;

    "theme.bar.floating" = true;
    "theme.bar.transparent" = true;
    "theme.bar.opacity" = 100;
    "theme.bar.background" = "rgba(0,0,0,0.0)";
    "theme.bar.border.color" = "rgba(0,0,0,0.0)";
    "theme.bar.margin_sides" = "0.35em";
    "theme.bar.margin_top" = "0.35em";
    "theme.bar.outer_spacing" = "0.35em";

    "theme.bar.buttons.style" = "default";
    "theme.bar.buttons.monochrome" = false;
    "theme.bar.buttons.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.hover" = "rgba(69,71,90,0.75)";
    "theme.bar.buttons.borderColor" = "rgba(205,214,244,0.08)";
    "theme.bar.buttons.radius" = "0.5rem";
    "theme.bar.buttons.padding_x" = "0.45rem";
    "theme.bar.buttons.padding_y" = "0.12rem";
    "theme.bar.buttons.y_margins" = "0.15em";
    "theme.bar.buttons.icon" = "#cdd6f4";
    "theme.bar.buttons.text" = "#cdd6f4";

    "theme.bar.buttons.dashboard.background" = "rgba(30,30,46,0.80)";
    "theme.bar.buttons.dashboard.icon" = "#89b4fa";
    "theme.bar.buttons.workspaces.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.workspaces.available" = "#6c7086";
    "theme.bar.buttons.workspaces.occupied" = "#bac2de";
    "theme.bar.buttons.workspaces.active" = "#f5e0dc";
    "theme.bar.buttons.windowtitle.text" = "#ffffff";
    "theme.bar.buttons.windowtitle.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.windowtitle.icon" = "#bac2de";
    "theme.bar.buttons.network.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.network.icon" = "#94e2d5";
    "theme.bar.buttons.network.text" = "#94e2d5";
    "theme.bar.buttons.modules.kbLayout.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.modules.kbLayout.icon" = "#f9e2af";
    "theme.bar.buttons.modules.kbLayout.text" = "#f9e2af";
    "theme.bar.buttons.bluetooth.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.bluetooth.icon" = "#89b4fa";
    "theme.bar.buttons.bluetooth.text" = "#89b4fa";
    "theme.bar.buttons.volume.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.volume.icon" = "#89b4fa";
    "theme.bar.buttons.volume.text" = "#89b4fa";
    "theme.bar.buttons.battery.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.battery.icon" = "#a6e3a1";
    "theme.bar.buttons.battery.text" = "#a6e3a1";
    "theme.bar.buttons.clock.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.clock.icon" = "#b4befe";
    "theme.bar.buttons.clock.text" = "#b4befe";
    "theme.bar.buttons.notifications.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.notifications.icon" = "#f5c2e7";
    "theme.bar.buttons.notifications.total" = "#f5c2e7";
    "theme.bar.buttons.systray.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.systray.customIcon" = "#cdd6f4";

    "theme.bar.menus.opacity" = 95;
    "theme.bar.menus.background" = "rgba(17,17,27,0.94)";
    "theme.bar.menus.card.color" = "rgba(30,30,46,0.95)";
    "theme.bar.menus.border.color" = "rgba(49,50,68,0.95)";
    "theme.bar.menus.text" = "#cdd6f4";
    "theme.bar.menus.label" = "#b4befe";
    "theme.bar.menus.dimtext" = "#7f849c";
    "theme.bar.menus.feinttext" = "#6c7086";
    "theme.bar.menus.iconbuttons.active" = "#b4befe";
    "theme.bar.menus.iconbuttons.passive" = "#bac2de";
    "theme.bar.menus.icons.active" = "#b4befe";
    "theme.bar.menus.icons.passive" = "#7f849c";
    "theme.bar.menus.listitems.active" = "#89b4fa";
    "theme.bar.menus.listitems.passive" = "#cdd6f4";
    "theme.bar.menus.switch.enabled" = "#89b4fa";
    "theme.bar.menus.switch.disabled" = "#585b70";
    "theme.bar.menus.switch.puck" = "#cdd6f4";
    "theme.bar.menus.progressbar.foreground" = "#89b4fa";
    "theme.bar.menus.progressbar.background" = "#313244";
  };

  nerdFont =
    if pkgs ? nerd-fonts.jetbrains-mono then
      pkgs.nerd-fonts.jetbrains-mono
    else
      pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };

  configFile = pkgs.writeText "hyprpanel-config.json" (builtins.toJSON hyprpanelConfig);
  modulesFile = pkgs.writeText "hyprpanel-modules.json" (builtins.toJSON customModules);
in
{
  programs.waybar.enable = lib.mkForce false;
  services.dunst.enable = lib.mkForce false;
  services.swaync.enable = lib.mkForce false;

  home.packages = [
    pkgs.hyprpanel
    nerdFont
  ];

  home.activation.hyprpanelConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/hyprpanel"
    $DRY_RUN_CMD rm -f "$HOME/.config/hyprpanel/config.json"
    $DRY_RUN_CMD rm -f "$HOME/.config/hyprpanel/modules.json"
    $DRY_RUN_CMD cp ${configFile} "$HOME/.config/hyprpanel/config.json"
    $DRY_RUN_CMD cp ${modulesFile} "$HOME/.config/hyprpanel/modules.json"
    $DRY_RUN_CMD chmod 644 "$HOME/.config/hyprpanel/config.json"
    $DRY_RUN_CMD chmod 644 "$HOME/.config/hyprpanel/modules.json"
  '';

  wayland.windowManager.hyprland.settings.exec-once = [
    "${pkgs.hyprpanel}/bin/hyprpanel"
  ];
}
