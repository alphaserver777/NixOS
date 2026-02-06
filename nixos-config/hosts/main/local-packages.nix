{ pkgs, ... }:

let
  lazyssh-client = pkgs.callPackage ../../packages/lazyssh.nix { };
in
{
  # Частные программы узла
  environment.systemPackages = with pkgs; [
    google-chrome
    telegram-desktop
    obs-studio
    obsidian
    syncthing
    amnezia-vpn
    keepassxc
    qbittorrent
    imv #pic
    mpv #video
    git
    anydesk
    pavucontrol

    # Office Suites
    libreoffice
    drawio
    xournalpp
    openboard

    # For Develop
    vscode
    gemini-cli
    google-cloud-sdk
    docker
    docker-compose
    neovim
    jq
    gcc
    dbeaver-bin
    sqlite
    python3

    # File manager
    nemo
    sshfs

    #CLI
    btop
    fzf # fast file search
    git-graph # visual for git
    ntfs3g # driver for NTFS
    ripgrep # fast text search
    lazyssh-client
    lazysql
    udisks # for USB
    ueberzugpp # pic in terminal
    w3m # web-browser in terminal

    # Archiving
    file-roller # визуальный архиватор
    unrar
    p7zip

    # System & Hardware
    alsa-utils # for alsamixer
    home-manager
    ntfs3g # driver for NTFS
    udisks2 # for USB and auto-mounting

    # kdenlive
    # jetbrains.pycharm-professional
    # jre8
    # qemu
    # quickemu
  ];
}
