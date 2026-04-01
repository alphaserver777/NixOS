{ lib, hostname ? null, ... }:
{
  imports = [
    ./alacritty.nix
    # ./bat.nix
    # ./chromium.nix
    ./eza.nix # красивый вывод папок и файлов
    ./flameshot.nix
    ./fzf.nix
    ./git.nix
    ./google-chrome.nix
    ./google-drive.nix
    ./gpg.nix
    ./hyprland
    ./hyprpanel.nix
    ./lazygit.nix
    ./atuin.nix
    # ./obsidian.nix
    ./pcmanfm.nix
    ./sshAgent.nix
    ./starship.nix
    ./stylix.nix
    ./tmux.nix
    ./zathura.nix # PDF reader
    ./zsh.nix
    ./zoxide.nix
    ./swaync
    ./nvim-config
    ./wofi
    ./ranger
  ] ++ lib.optionals (hostname != "srv-home") [
    ./rustdesk.nix
  ];
}
