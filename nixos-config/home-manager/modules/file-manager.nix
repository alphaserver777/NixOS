{ inputs, pkgs, lib, ... }:
let
  # Задача 010: новый выпуск и совместимые Pascal/Qt-зависимости из
  # уже закреплённого набора пакетов; остальная система не обновляется.
  newer = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
  };
in {
  home.packages = [ newer.doublecmd ];
  # Список обработчиков остаётся изменяемым приложениями. Задаём только
  # папки, сохраняя выбранный браузер, просмотр изображений и другие записи.
  home.activation.doubleCommanderDefault = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    file_manager_mime="''${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"
    if [ ! -e "$file_manager_mime" ] && [ -f "$file_manager_mime.backup" ]; then
      run cp "$file_manager_mime.backup" "$file_manager_mime"
    fi
    run ${pkgs.xdg-utils}/bin/xdg-mime default doublecmd.desktop inode/directory
  '';
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
