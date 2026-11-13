{ config, lib, pkgs, ... }:
{
  programs.navi = {
    enable = true;
    # Задача 051: подключаем после завершающего bindkey -e в zsh.nix.
    enableZshIntegration = false;
    enableBashIntegration = false;
    enableFishIntegration = false;
    settings.cheats.paths = [
      "${config.xdg.configHome}/navi/cheats"
      "${config.xdg.dataHome}/navi/cheats"
    ];
  };

  programs.tealdeer = {
    enable = true;
    enableAutoUpdates = false;
    settings = {
      search.languages = [ "ru" "en" ];
      updates = {
        auto_update = true;
        auto_update_interval_hours = 168;
      };
    };
  };

  # Обычный выбор печатает команду; Ctrl+G вставляет её без выполнения.
  programs.zsh.shellAliases.navi = "${pkgs.navi}/bin/navi --print";
  programs.zsh.initContent = lib.mkOrder 1600 ''
    if [[ $options[zle] = on ]]; then
      eval "$(${pkgs.navi}/bin/navi widget zsh)"
    fi
  '';

  xdg.configFile."navi/cheats".source = pkgs.runCommand "navi-russian-cheats" { } ''
    cp -r ${./command-cheats} "$out"
  '';
}
