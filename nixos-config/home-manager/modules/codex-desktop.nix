{ pkgs, lib, hostname, inputs, ... }:
let
  desktopPkgs = import inputs.nixpkgs-chatgpt {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  # Задача 047: приложение с окном устанавливается на рабочих машинах.
  home.packages = lib.optionals (builtins.elem hostname [ "Huawei" "main" "x-disk" ]) [
    # Штатная возможность пакета: сохранить CLI, поставляемый с приложением.
    (desktopPkgs.chatgpt.override { codex = null; })
  ];
}
