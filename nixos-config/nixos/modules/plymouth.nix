{ config, lib, pkgs, hostname, ... }:
{
  # Задача 055: заставка нужна только графическим рабочим окружениям.
  config = lib.mkIf (config.programs.hyprland.enable || config.services.xserver.enable) {
    boot.plymouth = {
      enable = true;
      theme = "black_hud";
      themePackages = [
        # Задача 057: только выбранная тема с плавно появляющейся подписью.
        (pkgs.callPackage ../../packages/plymouth-personal.nix { })
      ];
    };

    boot.consoleLogLevel = 3;
    boot.initrd.verbose = false;
    boot.kernelParams = [ "quiet" ];

    # Используем уже работающий драйвер Intel; остальные GPU не меняем.
    boot.initrd.kernelModules = lib.optionals
      (builtins.elem hostname [ "x-disk" "Huawei" ]) [ "i915" ];
  };
}
