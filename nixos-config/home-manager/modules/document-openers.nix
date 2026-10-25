{ pkgs, lib, ... }:
{
  # Задача 039: у каждого назначенного обработчика есть установленная программа.
  home.packages = [ pkgs.vscode ];

  xdg.desktopEntries.nixos-text-editor = {
    name = "Текст и Markdown";
    genericName = "Текстовый редактор";
    exec = "${pkgs.vscode}/bin/code --reuse-window -- %F";
    icon = "vscode";
    terminal = false;
    categories = [ "Utility" "TextEditor" ];
    mimeType = [ "text/plain" "text/markdown" "text/x-markdown" ];
    startupNotify = true;
  };

  # Сохраняем изменяемый mimeapps.list и остальные пользовательские назначения.
  # Запускаем после восстановления файла в общем модуле файлового менеджера.
  home.activation.textDocumentDefaults = lib.hm.dag.entryAfter [ "doubleCommanderDefault" ] ''
    run ${pkgs.xdg-utils}/bin/xdg-mime default nixos-text-editor.desktop \
      text/plain text/markdown text/x-markdown
  '';
}
