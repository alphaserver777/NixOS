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
    imv #pic
    mpv #video
    #CLI
    btop
    git-graph # visual for git
    ntfs3g # driver for NTFS
    ripgrep # fast text search
    udisks # for USB
    ueberzugpp # pic in terminal
    w3m # web-browser in terminal
    zip
    unzip
    neovim
    docker
    docker-compose

    #network
    speedtest-cli
    iperf3
    mtr
    wavemon
    # gcc
    # kdenlive
    # jetbrains.pycharm-professional
    # jre8
    # qemu
    # quickemu
  ];
}
