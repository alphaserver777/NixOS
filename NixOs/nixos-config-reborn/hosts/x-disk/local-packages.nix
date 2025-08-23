{ pkgs, ... }: {
  # Частные программы узла
  environment.systemPackages = with pkgs; [
    google-chrome
    zed-editor
    btop
    telegram-desktop
    obsidian
    syncthing
    amnezia-vpn
    keepass
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
