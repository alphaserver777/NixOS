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
    anydesk
    wpsoffice
    drawio
    pavucontrol


    # For Develop
    gemini-cli
    google-cloud-sdk
    docker
    docker-compose
    vscode
    termius

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
    unrar
    unzip
    p7zip
    home-manager
    neovim
    jq

    # gcc
    # kdenlive
    # jetbrains.pycharm-professional
    # jre8
    # qemu
    # quickemu
  ];
}
