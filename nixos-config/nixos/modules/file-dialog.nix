{ pkgs, ... }: {
  # Задача 012: готовое окно KDE только для открытия и сохранения файлов.
  xdg.portal = {
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk
    ];
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" "gtk" ];
    };
  };
  # Существующее оформление Stylix/Qt6ct. Qt5-параметры других приложений
  # не подменяются, KDE не становится рабочим столом или файловым менеджером.
  systemd.user.services.plasma-xdg-desktop-portal-kde = {
    overrideStrategy = "asDropin";
    serviceConfig.Environment = [
      "QT_QPA_PLATFORMTHEME=qt6ct"
      "QT_STYLE_OVERRIDE=kvantum"
      "LANGUAGE=ru"
    ];
  };
}
