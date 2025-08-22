{ pkgs, ... }: {
  # Частные программы узла
  environment.systemPackages = with pkgs; [
    google-chrome
    telegram-desktop
    # obsidian
    syncthing
    amnezia-vpn
    # keepass
    # qbittorrent
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
