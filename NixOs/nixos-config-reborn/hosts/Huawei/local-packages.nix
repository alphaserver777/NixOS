{ pkgs, ... }: {
# Частные программы узла
  environment.systemPackages = with pkgs; [
    google-chrome
      btop
      telegram-desktop
      obsidian
      syncthing
      amnezia-vpn
      qbittorrent
      home-manager
      neovim
# gcc
# kdenlive
# jetbrains.pycharm-professional
# jre8
# qemu
# quickemu
  ];
               }
