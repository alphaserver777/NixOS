{ pkgs, ... }: {
# Частные программы узла
  environment.systemPackages = with pkgs; [
    google-chrome
      zed-editor
      telegram-desktop
      obsidian
      syncthing
      amnezia-vpn
      keepassxc
      qbittorrent
      imv #pic
      mpv #video

#CLI
      btop
      fzf # fast file search
      git-graph # visual for git
      ntfs3g # driver for NTFS
      ripgrep # fast text search
      udisks # for USB
      ueberzugpp # pic in terminal
      w3m # web-browser in terminal
      zip
      unzip
      p7zip
      home-manager
      neovim
      nixvim
      jq

# gcc
# kdenlive
# jetbrains.pycharm-professional
# jre8
# qemu
# quickemu
      ];
               }
