{ config, pkgs, ... }:
let
  screenshot = pkgs.writeShellScript "screenshot" ''
    set -eu
    mkdir -p "$HOME/screens"
    file="$HOME/screens/$(date +%Y-%m-%d_%H-%M-%S-%N).png"
    mode="''${1:-area}"
    ${pkgs.grimblast}/bin/grimblast --notify copysave "$mode" "$file"
  '';
  toggleMicrophone = pkgs.writeShellScript "toggle-microphone" ''
    ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

    if ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | ${pkgs.gnugrep}/bin/grep -q '\[MUTED\]'; then
      ${pkgs.pipewire}/bin/pw-play ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-warning.oga &
    else
      ${pkgs.pipewire}/bin/pw-play ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga &
    fi
  '';
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mainMod,       T, exec, $terminal"
      "$mainMod,       Q, killactive,"
      "$mainMod CTRL,  M, exit,"
      "$mainMod SHIFT, M, exec, poweroff"
      "$mainMod ALT,   M, exec, reboot"
      "$mainMod,       R, exec, cosmic-dms ipc spotlight toggle"
      "$mainMod,   SPACE, exec, cosmic-dms ipc spotlight toggle"
      "$mainMod,       M, exec, cosmic-mode menu"
      "$mainMod CTRL,  W, exec, cosmic-mode work"
      "$mainMod CTRL,  V, exec, cosmic-mode video"
      "$mainMod CTRL,  P, exec, cosmic-mode show"
      "$mainMod CTRL, BackSpace, exec, cosmic-mode normal"
      "$mainMod,       D, exec, cosmic-dms ipc cosmic-center toggle"
      ''$mainMod SHIFT, D, exec, cosmic-dms ipc dash toggle ""''
      "$mainMod SHIFT, I, exec, cosmic-screensaver choose"
      "$mainMod SHIFT, R, exec, $fileManager"
      "$mainMod,       E, exec, $fileManager"
      "$mainMod,       G, exec, google-chrome-stable --ozone-platform=wayland --disable-gpu"
      "$mainMod,       C, exec, telegram-desktop"
      "$mainMod,       A, exec, amnezia-vpn"
      "$mainMod,       F, togglefloating,"
      "$mainMod,       P, pin,"
      "$mainMod,       J, layoutmsg, orientationcycle left top right bottom"
      "$mainMod,     Tab, exec, hyprctl dispatch overview:toggle all"
      "$mainMod,       V, exec, cosmic-dms ipc clipboard toggle"
      "$mainMod,       L, exec, loginctl lock-session"
      "$mainMod,       N, exec, cosmic-dms ipc notifications toggle"
      ", Print, exec, ${config.services.flameshot.package}/bin/flameshot gui"
      "SHIFT, Print, exec, ${screenshot} output"
      "CTRL, Print, exec, ${screenshot} screen"
      "$mainMod, F12, exec, ${config.services.flameshot.package}/bin/flameshot gui"
      "$mainMod SHIFT, F12, exec, obs"

      # Moving focus
      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"

      # Moving windows
      "$mainMod SHIFT, left,  swapwindow, l"
      "$mainMod SHIFT, right, swapwindow, r"
      "$mainMod SHIFT, up,    swapwindow, u"
      "$mainMod SHIFT, down,  swapwindow, d"

      # Resizeing windows                   X  Y
      "$mainMod CTRL, left,  resizeactive, -60 0"
      "$mainMod CTRL, right, resizeactive,  60 0"
      "$mainMod CTRL, up,    resizeactive,  0 -60"
      "$mainMod CTRL, down,  resizeactive,  0  60"

      # Switching workspaces
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"

      # Moving windows to workspaces
      "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
      "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
      "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
      "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
      "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
      "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
      "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
      "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
      "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
      "$mainMod SHIFT, 0, movetoworkspacesilent, 10"

      # Scratchpad
      "$mainMod,       S, togglespecialworkspace,  magic"
      "$mainMod SHIFT, S, movetoworkspace, special:magic"
    ];

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

    # Laptop multimedia keys for volume and LCD brightness
    bindel = [
      ",XF86AudioRaiseVolume,  exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86AudioMute,         exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioMicMute,      exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ",KP_Multiply,          exec, ${toggleMicrophone}"
      "$mainMod, bracketright, exec, brightnessctl s 10%+"
      "$mainMod, bracketleft,  exec, brightnessctl s 10%-"
    ];

    # Audio playback
    bindl = [
      ", XF86AudioNext,  exec, playerctl next"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioPlay,  exec, playerctl play-pause"
      ", XF86AudioPrev,  exec, playerctl previous"
    ];
  };
}
