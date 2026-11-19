{ config, lib, pkgs, hostname, ... }:
{
  # Задача 055: заставка нужна только графическим рабочим окружениям.
  config = lib.mkIf (config.programs.hyprland.enable || config.services.xserver.enable) {
    boot.plymouth = {
      enable = true;
      theme = "hud_space";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override {
          selected_themes = [ "hud_space" ];
        })
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
