{ user, ... }:

{
  services.syncthing = {
    enable = true;
    user = user;
    group = "users";
    dataDir = "/home/${user}/Obsidian";
    configDir = "/home/${user}/.config/syncthing";
  };
}
