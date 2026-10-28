{ pkgs, lib, hostname, ... }:

{
  # Задача 047: приложение с окном устанавливается на рабочих машинах.
  home.packages = lib.optionals (builtins.elem hostname [ "Huawei" "main" "x-disk" ]) [
    (pkgs.callPackage ../../packages/chatgpt-desktop.nix { })
  ];
}
