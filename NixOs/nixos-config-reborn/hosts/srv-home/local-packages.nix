{ pkgs, ... }: {
  # Частные программы узла
  environment.systemPackages = with pkgs; [
    google-chrome
    btop
    telegram-desktop
    # obsidian
    syncthing
    amnezia-vpn
    # keepass
    # qbittorrent
    home-manager
    neovim
    docker
    docker-compose
    # gcc
    # kdenlive
    # jetbrains.pycharm-professional
    # jre8
    # qemu
    # quickemu
  ];
}
