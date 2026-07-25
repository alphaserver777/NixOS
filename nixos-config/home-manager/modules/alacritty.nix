{ config, pkgs, lib, ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 1.0;

      # Выделенный текст сразу отправляется в буфер обмена Alacritty.
      selection.save_to_clipboard = true;

      # Разрешить локальным и удалённым программам только запись через OSC 52.
      terminal.osc52 = "OnlyCopy";

      font = {
        builtin_box_drawing = true;
        normal = {
          family = "JetBrains Mono";
          style = lib.mkDefault "Bold";
        };
        size = lib.mkForce 14.0;
      };
    };
  };
}
