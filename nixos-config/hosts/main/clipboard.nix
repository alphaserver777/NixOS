{ pkgs, user, ... }:

{
  # Задача 017: пути к пакетам не зависят от личного профиля Nix.
  home-manager.users.${user}.systemd.user.services.wayland-to-x11-clipboard = {
    Unit = {
      Description = "Передача текста буфера обмена из Wayland в X11";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.xclip}/bin/xclip -selection clipboard";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
