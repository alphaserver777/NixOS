{ inputs, pkgs, ... }:
let
  # Задача 010: новый выпуск и совместимые Pascal/Qt-зависимости из
  # уже закреплённого набора пакетов; остальная система не обновляется.
  newer = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
  };
in {
  home.packages = [ newer.doublecmd ];
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = [ "doublecmd.desktop" ];
    associations.added."inode/directory" = [ "doublecmd.desktop" ];
  };
  # Повторный запуск открывает папку в существующем окне.
  xdg.desktopEntries.doublecmd = {
    name = "Double Commander";
    genericName = "Файловый менеджер";
    exec = "${newer.doublecmd}/bin/doublecmd --client --no-splash %F";
    icon = "doublecmd";
    terminal = false;
    categories = [ "Utility" "FileManager" ];
    mimeType = [ "inode/directory" ];
    startupNotify = true;
  };
}
