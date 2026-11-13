{ config, lib, pkgs, ... }:
let
  # Задача 052: общий готовый справочник доступен без загрузки при поиске.
  tldrCatalog = pkgs.fetchFromGitHub {
    owner = "denisidoro";
    repo = "navi-tldr-pages";
    rev = "636c02e165683986f5e15bb14b66b8bc0df478a1";
    hash = "sha256-lsJsHnu7v33lg6Jacy5mf6cdDFy4Y1VYnHlnK46gLG8=";
  };
in
{
  programs.navi = {
    enable = true;
    # Задача 051: подключаем после завершающего bindkey -e в zsh.nix.
    enableZshIntegration = false;
    enableBashIntegration = false;
    enableFishIntegration = false;
    settings = {
      client.tealdeer = true;
      cheats.paths = [
        "${config.xdg.configHome}/navi/cheats"
        "${tldrCatalog}/pages/linux"
        "${tldrCatalog}/pages/common"
        "${config.xdg.dataHome}/navi/cheats"
      ];
    };
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
