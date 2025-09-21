{
  services.syncthing = {
    enable = true;
    user = "admsys";
    group = "users";
    dataDir = "/home/admsys/Obsidian";
    configDir = "/home/admsys/.config/syncthing";
  };
}

