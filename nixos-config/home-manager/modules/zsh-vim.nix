{ lib, pkgs, ... }:
let
  vimSetup = pkgs.replaceVars ./zsh-vim.zsh {
    viMode = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
    nvim = "${pkgs.neovim}/bin/nvim";
    tmux = "${pkgs.tmux}/bin/tmux";
  };
in
{
  # После основных сочетаний (1500) и Navi (1600).
  programs.zsh.initContent = lib.mkOrder 1700 ''
    if [[ $options[zle] = on ]]; then
      source ${vimSetup}
    fi
  '';
  # Название режима показывается только в tmux.
  programs.starship.settings.character = {
    vimcmd_symbol = "[ & ](bold green)";
    vimcmd_visual_symbol = "[ & ](bold green)";
    vimcmd_replace_symbol = "[ & ](bold green)";
    vimcmd_replace_one_symbol = "[ & ](bold green)";
  };
}
