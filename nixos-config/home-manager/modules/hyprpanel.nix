{ lib, pkgs, ... }:
let
  theme = builtins.fromJSON (
    builtins.readFile "${pkgs.hyprpanel}/share/themes/tokyo_night_moon_split.json"
  );

  weatherScript = pkgs.writeShellScript "hyprpanel-weather-krasnodar" ''
    weather=$(
      ${pkgs.curl}/bin/curl -fsS --max-time 3 'https://wttr.in/Krasnodar?format=%c%20%t' 2>/dev/null \
        | ${pkgs.gnused}/bin/sed -e 's/+//g' -e 's/[[:space:]]*$//'
    ) || true

    if [ -n "$weather" ]; then
      printf '%s\n' "$weather"
    else
      printf '󰖐 --°C\n'
    fi
  '';

  cryptoPriceScript = pkgs.writeShellScript "hyprpanel-crypto-price" ''
    set -eu

    state_dir="${"$"}HOME/.config/hyprpanel"
    state_file="$state_dir/crypto-symbol"

    ${pkgs.coreutils}/bin/mkdir -p "$state_dir"

    if [ -r "$state_file" ]; then
      symbol="$(${pkgs.coreutils}/bin/cat "$state_file")"
    else
      symbol="BTCUSDT"
    fi

    case "$symbol" in
      BTCUSDT) short="BTC" ;;
      ETHUSDT) short="ETH" ;;
      SOLUSDT) short="SOL" ;;
      BNBUSDT) short="BNB" ;;
      XRPUSDT) short="XRP" ;;
      ADAUSDT) short="ADA" ;;
      DOGEUSDT) short="DOGE" ;;
      TONUSDT) short="TON" ;;
      *) short="$symbol" ;;
    esac

    price="$(
      ${pkgs.curl}/bin/curl -fsS --max-time 4 "https://api.binance.com/api/v3/ticker/price?symbol=$symbol" 2>/dev/null \
        | ${pkgs.jq}/bin/jq -r '.price // empty' 2>/dev/null
    )" || true

    if [ -z "$price" ]; then
      printf '%s $--\n' "$short"
      exit 0
    fi

    pretty="$(${pkgs.gawk}/bin/awk -v p="$price" '
      BEGIN {
        if (p >= 1000)      printf "%.0f", p
        else if (p >= 1)    printf "%.2f", p
        else                printf "%.4f", p
      }
    ')"

    printf '%s $%s\n' "$short" "$pretty"
  '';

  cryptoSelectScript = pkgs.writeShellScript "hyprpanel-crypto-select" ''
    set -eu

    state_dir="${"$"}HOME/.config/hyprpanel"
    state_file="$state_dir/crypto-symbol"

    ${pkgs.coreutils}/bin/mkdir -p "$state_dir"

    selected="$(
      ${pkgs.coreutils}/bin/printf '%s\n' \
        'BTCUSDT  BTC  Bitcoin' \
        'ETHUSDT  ETH  Ethereum' \
        'SOLUSDT  SOL  Solana' \
        'BNBUSDT  BNB  BNB' \
        'XRPUSDT  XRP  XRP' \
        'ADAUSDT  ADA  Cardano' \
        'DOGEUSDT  DOGE  Dogecoin' \
        'TONUSDT  TON  Toncoin' \
        | ${pkgs.wofi}/bin/wofi --dmenu --prompt 'Crypto' \
        | ${pkgs.gawk}/bin/awk '{print $1}'
    )"

    if [ -n "$selected" ]; then
      printf '%s\n' "$selected" > "$state_file"
    fi
  '';

  restartHyprpanel = pkgs.writeShellScriptBin "restart-hyprpanel" ''
    set -eu

    socket_dir="/run/user/$(${pkgs.coreutils}/bin/id -u)/astal"
    socket="$socket_dir/hyprpanel.sock"
    log_file="${"$"}HOME/.cache/hyprpanel.log"

    ${pkgs.coreutils}/bin/mkdir -p "$socket_dir" "${"$"}HOME/.cache"

    ${pkgs.procps}/bin/pkill -f '(^|/)(hyprpanel|\.hyprpanel-wrapped)( |$)' 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x dunst 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x swaync 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x waybar 2>/dev/null || true
    ${pkgs.coreutils}/bin/rm -rf /tmp/hyprpanel
    ${pkgs.coreutils}/bin/rm -f "$socket"
    ${pkgs.coreutils}/bin/sleep 1

    ${pkgs.util-linux}/bin/setsid ${pkgs.hyprpanel}/bin/hyprpanel >"$log_file" 2>&1 < /dev/null &
  '';

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
    "custom/weather-krasnodar" = {
      label = "{}";
      tooltip = "Weather: Krasnodar";
      interval = 900;
      hideOnEmpty = false;
      execute = "${weatherScript}";
    };
    "custom/crypto-price" = {
      label = "{}";
      tooltip = "Crypto Price";
      interval = 30;
      execute = "${cryptoPriceScript}";
      executeOnAction = "${cryptoPriceScript}";
      actions.onLeftClick = "${cryptoSelectScript}";
    };
  };

  hyprpanelConfig = theme // {
    "bar.autoHide" = "never";
    "bar.clock.format" = "%d %b %H:%M";
    "bar.clock.showIcon" = false;
    "bar.bluetooth.label" = false;
    "bar.network.label" = true;
    "bar.volume.label" = true;
    "bar.customModules.cpu.icon" = "󰍛";
    "bar.customModules.cpu.label" = true;
    "bar.customModules.cpu.round" = true;
    "bar.customModules.cpu.pollingInterval" = 2000;
    "bar.customModules.ram.icon" = "󰘚";
    "bar.customModules.ram.label" = true;
    "bar.customModules.ram.labelType" = "percentage";
    "bar.customModules.ram.round" = true;
    "bar.customModules.ram.pollingInterval" = 2000;
    "bar.customModules.storage.icon" = "󰋊";
    "bar.customModules.storage.label" = true;
    "bar.customModules.storage.labelType" = "percentage";
    "bar.customModules.storage.paths" = [ "/" ];
    "bar.customModules.storage.units" = "gibibytes";
    "bar.customModules.storage.tooltipStyle" = "simple";
    "bar.customModules.storage.round" = true;
    "bar.customModules.storage.pollingInterval" = 10000;
    "bar.customModules.netstat.networkInterface" = "";
    "bar.customModules.netstat.dynamicIcon" = true;
    "bar.customModules.netstat.icon" = "󰇚";
    "bar.customModules.netstat.label" = true;
    "bar.customModules.netstat.networkInLabel" = "↓";
    "bar.customModules.netstat.networkOutLabel" = "↑";
    "bar.customModules.netstat.labelType" = "full";
    "bar.customModules.netstat.rateUnit" = "auto";
    "bar.customModules.netstat.round" = true;
    "bar.customModules.netstat.pollingInterval" = 2000;
    "bar.customModules.microphone.label" = false;
    "bar.customModules.microphone.mutedIcon" = "🔴";
    "bar.customModules.microphone.unmutedIcon" = "🟢";
    "bar.customModules.microphone.leftClick" = "";
    "bar.customModules.microphone.rightClick" = "";
    "bar.customModules.microphone.middleClick" = "";
    "bar.customModules.microphone.scrollUp" = "";
    "bar.customModules.microphone.scrollDown" = "";
    "bar.customModules.kbLayout.label" = true;
    "bar.customModules.kbLayout.labelType" = "code";
    "bar.customModules.kbLayout.icon" = "󰌌";
    "bar.customModules.hypridle.label" = false;
    "bar.customModules.hypridle.pollingInterval" = 1000;
    "bar.customModules.hypridle.offIcon" = "";
    "bar.customModules.hypridle.onIcon" = "";
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
        left = [ "dashboard" "workspaces" "battery" "cpu" "ram" "storage" "netstat" ];
        middle = [ "windowtitle" ];
        right = [ "hypridle" "custom/crypto-price" "systray" "custom/keyboard-flags" "network" "bluetooth" "volume" "microphone" "custom/weather-krasnodar" "clock" "notifications" ];
      };
      "1" = {
        left = [ "dashboard" "workspaces" "battery" "cpu" "ram" "storage" "netstat" ];
        middle = [ "windowtitle" ];
        right = [ "hypridle" "custom/crypto-price" "systray" "custom/keyboard-flags" "network" "bluetooth" "volume" "microphone" "custom/weather-krasnodar" "clock" "notifications" ];
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
    "theme.bar.buttons.modules.microphone.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.modules.microphone.icon" = "#a6e3a1";
    "theme.bar.buttons.modules.microphone.text" = "#a6e3a1";
    "theme.bar.buttons.modules.hypridle.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.modules.hypridle.icon" = "#fab387";
    "theme.bar.buttons.modules.hypridle.text" = "#fab387";
    "theme.bar.buttons.bluetooth.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.bluetooth.icon" = "#89b4fa";
    "theme.bar.buttons.bluetooth.text" = "#89b4fa";
    "theme.bar.buttons.volume.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.volume.icon" = "#89b4fa";
    "theme.bar.buttons.volume.text" = "#89b4fa";
    "theme.bar.buttons.modules.cpu.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.modules.cpu.icon" = "#f38ba8";
    "theme.bar.buttons.modules.cpu.text" = "#f38ba8";
    "theme.bar.buttons.modules.ram.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.modules.ram.icon" = "#f9e2af";
    "theme.bar.buttons.modules.ram.text" = "#f9e2af";
    "theme.bar.buttons.modules.storage.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.modules.storage.icon" = "#a6e3a1";
    "theme.bar.buttons.modules.storage.text" = "#a6e3a1";
    "theme.bar.buttons.modules.netstat.background" = "rgba(17,17,27,0.72)";
    "theme.bar.buttons.modules.netstat.icon" = "#89dceb";
    "theme.bar.buttons.modules.netstat.text" = "#89dceb";
    "theme.bar.middle.spacing" = "0.2em";
    "theme.bar.buttons.windowtitle.enableBorder" = false;
    "theme.bar.buttons.windowtitle.maxWidth" = "18em";
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
  modulesScssFile = pkgs.writeText "hyprpanel-modules.scss" ''
    .cmodule-crypto-price {
      min-width: 7.8em;
    }

    .cmodule-crypto-price .module-label {
      color: #f5c2e7;
      font-weight: 700;
    }

    .battery .module-label {
      min-width: 4.2em;
    }

    .cpu .module-label,
    .ram .module-label {
      min-width: 4.0em;
    }

    .storage .module-label {
      min-width: 4.8em;
    }

    .netstat .module-label {
      min-width: 11.5em;
    }

    .cmodule-weather-krasnodar {
      min-width: 5.8em;
    }

    .cmodule-weather-krasnodar .module-label {
      color: #89dceb;
      font-weight: 700;
    }
  '';
in
{
  programs.waybar.enable = lib.mkForce false;
  services.dunst.enable = lib.mkForce false;
  services.swaync.enable = lib.mkForce false;

  home.packages = [
    pkgs.hyprpanel
    nerdFont
    restartHyprpanel
  ];

  home.activation.hyprpanelConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/hyprpanel"
    tmp_dir="$HOME/.config/hyprpanel/.hm-tmp"
    $DRY_RUN_CMD rm -rf "$tmp_dir"
    $DRY_RUN_CMD mkdir -p "$tmp_dir"
    $DRY_RUN_CMD cp ${configFile} "$tmp_dir/config.json"
    $DRY_RUN_CMD cp ${modulesFile} "$tmp_dir/modules.json"
    $DRY_RUN_CMD cp ${modulesScssFile} "$tmp_dir/modules.scss"
    $DRY_RUN_CMD chmod 644 "$tmp_dir/config.json"
    $DRY_RUN_CMD chmod 644 "$tmp_dir/modules.json"
    $DRY_RUN_CMD chmod 644 "$tmp_dir/modules.scss"
    $DRY_RUN_CMD mv -f "$tmp_dir/config.json" "$HOME/.config/hyprpanel/config.json"
    $DRY_RUN_CMD mv -f "$tmp_dir/modules.json" "$HOME/.config/hyprpanel/modules.json"
    $DRY_RUN_CMD mv -f "$tmp_dir/modules.scss" "$HOME/.config/hyprpanel/modules.scss"
    $DRY_RUN_CMD rmdir "$tmp_dir"
  '';

  wayland.windowManager.hyprland.settings.exec-once = [
    "${restartHyprpanel}/bin/restart-hyprpanel"
  ];
}
