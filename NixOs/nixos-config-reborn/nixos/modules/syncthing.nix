{
  services.syncthing = {
    enable = true;
    user = "syncthing";
    group = "syncthing";
    dataDir = "/var/lib/syncthing";
    configDir = "/var/lib/syncthing/.config/syncthing";
  };

  users.users.syncthing = {
    isSystemUser = true;
    group = "syncthing";
    createHome = true;
    home = "/var/lib/syncthing";
  };

  systemd.tmpfiles.rules = [
# Синтаксис: <тип> <путь> <права> <владелец> <группа> <возраст> <аргумент>
    "d /var/lib/syncthing 775 syncthing syncthing -"
  ];

# journalctl -u syncthing
# systemctl status syncthing

}
