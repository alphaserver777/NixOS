{ pkgs, lib, hostname, ... }:
lib.mkIf (hostname == "x-disk") {
  # Задача 013: однократный выбор бесплатной модели; дальнейший выбор
  # пользователя и прочие личные настройки сохраняются.
  home.activation.opencodeFreeDefault = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.python3}/bin/python3 ${./opencode-default.py}
  '';
}
