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

  # Обычный вызов и Ctrl+G подставляют команду без её выполнения.
  programs.zsh.initContent = lib.mkOrder 1600 ''
    navi() {
      if (( $# )); then
        ${pkgs.navi}/bin/navi "$@"
        return
      fi
      local selected
      selected="$(${pkgs.navi}/bin/navi --print)" || return
      if [[ -n "$selected" ]]; then
        print -z -- "$selected"
      fi
    }
    if [[ $options[zle] = on ]]; then
      eval "$(${pkgs.navi}/bin/navi widget zsh)"
    fi
  '';

  xdg.configFile."navi/cheats".source = pkgs.runCommand "navi-russian-cheats" { } ''
    cp -r ${./command-cheats} "$out"
  '';
}
