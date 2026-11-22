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
  # Режим берётся из zsh-vi-mode, включая выделение и замену.
  programs.starship.settings.character.disabled = true;
}
