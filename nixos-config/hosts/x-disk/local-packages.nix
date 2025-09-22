{ pkgs, ... }: {
  # Частные программы узла
  environment.systemPackages = with pkgs; [
    google-chrome
    telegram-desktop
    obsidian
    syncthing
    amnezia-vpn
    keepassxc
    qbittorrent
    imv #pic
    mpv #video
    wpsoffice

    # For Develop
    vscode
    gemini-cli
    google-cloud-sdk
    docker
    docker-compose

    # File manager
    pcmanfm

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
    home-manager
    neovim
    jq
    gcc
    # kdenlive
    # jetbrains.pycharm-professional
    # jre8
    # qemu
    # quickemu
  ];
}
