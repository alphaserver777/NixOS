{ pkgs, ... }: {
  # Частные программы узла
  environment.systemPackages = with pkgs; [
    google-chrome
    telegram-desktop
    qtox
    obsidian
    syncthing
    amnezia-vpn
    keepassxc
    qbittorrent
    imv #pic
    mpv #video
    pavucontrol
    anydesk

    # Office Suites
    libreoffice
    drawio

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
    nemo
    gvfs

    # --- CLI ---
    # System Monitoring
    btop

    # File Search & Manipulation
    duf
    ncdu # disk usage analyzer
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
    udisks2 # for USB and auto-mounting

    # Web & Terminal
    ueberzugpp # pic in terminal
    w3m # web-browser in terminal

    # Archiving
    file-roller # визуальный архиватор
    zip
    unzip
    p7zip
    # kdenlive
    # jetbrains.pycharm-professional
    # jre8
    # qemu
    # quickemu

    # AI
    gemini-cli

  ];
}
