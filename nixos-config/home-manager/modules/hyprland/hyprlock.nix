{ pkgs, ... }:
let
  weekday = pkgs.writeShellScript "cosmic-lock-weekday" ''
    export LC_ALL=C
    name="$(${pkgs.coreutils}/bin/date +'%A' | ${pkgs.coreutils}/bin/tr '[:lower:]' '[:upper:]')"
    printf '<span letter_spacing="6144">%s</span>\n' "$name"
  '';
  date = pkgs.writeShellScript "cosmic-lock-date" ''
    export LC_ALL=C
    day="$(${pkgs.coreutils}/bin/date +'%d')"
    month="$(${pkgs.coreutils}/bin/date +'%B' | ${pkgs.coreutils}/bin/tr '[:lower:]' '[:upper:]')"
    year="$(${pkgs.coreutils}/bin/date +'%Y')"
    printf '<span letter_spacing="2048">%s <span font_family="Anurati">%s</span> %s</span>\n' "$day" "$month" "$year"
  '';
in
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general.hide_cursor = true;

      background = [{
        monitor = "";
        # Интерполяция копирует сам файл в хранилище Nix и сохраняет зависимость.
        path = "${../../../wallpapers/space.png}";
        color = "rgb(30, 30, 46)";
        blur_passes = 2;
        blur_size = 3;
        contrast = 1.0;
        brightness = 0.8;
        vibrancy = 0.15;
      }];

      label = [
        {
          monitor = "";
          text = "cmd[update:60000] ${weekday}";
          color = "rgb(205, 214, 244)";
          font_size = 52;
          font_family = "Anurati";
          shadow_passes = 2;
          position = "0, 300";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "<span letter_spacing=\"2048\">$TIME</span>";
          color = "rgb(205, 214, 244)";
          font_size = 96;
          font_family = "Cosmic Stencil";
          shadow_passes = 2;
          position = "0, 180";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:60000] ${date}";
          color = "rgb(186, 187, 241)";
          font_size = 24;
          font_family = "Cosmic Stencil";
          shadow_passes = 2;
          position = "0, 85";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "$USER · $LAYOUT";
          color = "rgb(166, 173, 200)";
          font_size = 16;
          font_family = "Noto Sans";
          position = "0, -105";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "Сеанс заблокирован";
          color = "rgb(166, 173, 200)";
          font_size = 14;
          font_family = "Noto Sans";
          position = "0, 45";
          halign = "center";
          valign = "bottom";
        }
      ];

      input-field = [{
        monitor = "";
        position = "0, -20";
        halign = "center";
        valign = "center";
        size = "360, 64";
        rounding = 18;
        font_family = "Noto Sans";
        font_color = "rgb(205, 214, 244)";
        inner_color = "rgba(30, 30, 46, 0.85)";
        outer_color = "rgb(137, 180, 250) rgb(203, 166, 247) 45deg";
        check_color = "rgb(166, 227, 161)";
        fail_color = "rgb(243, 139, 168)";
        capslock_color = "rgb(249, 226, 175)";
        outline_thickness = 2;
        dots_center = true;
        placeholder_text = "Введите пароль";
        fail_text = "Неверный пароль · попытка $ATTEMPTS";
        fade_on_empty = false;
        shadow_passes = 2;
      }];
    };
  };
}
