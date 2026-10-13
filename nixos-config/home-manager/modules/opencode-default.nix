{ pkgs, lib, ... }:
{
  # Задачи 013/023: однократный выбор бесплатной модели на всех хостах; дальнейший выбор
  # пользователя и прочие личные настройки сохраняются.
  home.activation.opencodeFreeDefault = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.python3}/bin/python3 ${./opencode-default.py}
  '';
}
