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
    pavucontrol

    # Office Suites
    libreoffice

    # For Develop
    vscode
    google-cloud-sdk
    docker
    docker-compose
    postman
    python3

    # Pentest
    nmap
    smbmap
    metasploit
    traceroute

    # File manager
    pcmanfm

    # --- CLI ---
    # System Monitoring
    btop

    # File Search & Manipulation
    duf
    fd
    fzf # fast file search
    ripgrep # fast text search

    # Development & Text Editing
    gcc
    git-graph # visual for git
    jq
    neovim

    # System & Hardware
    alsa-utils # for alsamixer
    home-manager
    ntfs3g # driver for NTFS
    udisks # for USB

    # Web & Terminal
    ueberzugpp # pic in terminal
    w3m # web-browser in terminal

    # Archiving
    zip
    unzip
    # kdenlive
    # jetbrains.pycharm-professional
    # jre8
    qemu
    # quickemu

    # A
    gemini-cli

  ];
}
