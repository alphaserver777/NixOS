{
  services.syncthing = {
    enable = true;
    user = "syncthing";
    group = "syncthing";
    dataDir = "/var/lib/syncthing";
    configDir = "/var/lib/syncthing/.config/syncthing";
  };

# journalctl -u syncthing
# systemctl status syncthing
# Этот скрипт запускается после старта службы syncthing,
# чтобы установить правильные права доступа к каталогу данных.
# Syncthing при запуске сбрасывает права на 700, поэтому это необходимо.
  systemd.services.syncthing.postStart = ''
    /run/current-system/sw/bin/chmod -R 775 /var/lib/syncthing
    '';
}
