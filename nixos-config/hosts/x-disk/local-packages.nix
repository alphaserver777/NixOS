{ pkgs, pkgs-unstable, opencodePackage, antigravityCliPackage, ... }:
let
  lazyssh-client = pkgs.callPackage ../../packages/lazyssh.nix { };
in
{
  # Частные программы узла
  environment.systemPackages = with pkgs; [
    google-chrome
    tor-browser
    qtox
    obsidian
    syncthing
    keepassxc
    qbittorrent
    imv #pic
    grim
    slurp
    ksnip
    mpv #video
    pavucontrol
    networkmanagerapplet
    wireshark

    # Office Suites
    libreoffice
    drawio
    flameshot

    # For Develop
    vscode
    google-cloud-sdk
    docker
    docker-compose
    postman
    beekeeper-studio
    python3
    lazyssh-client
    sshfs
    ansible


    # Pentest
    nmap
    smbmap
    metasploit
    traceroute
    mtr

    # File manager
    doublecmd
    pcmanfm
    nemo
    gvfs

    # --- CLI ---
    # System Monitoring
    btop
    smartmontools # for smartctl
    sysstat # for iostat

    # File Search & Manipulation
    duf
    ncdu # disk usage analyzer
    fd
    fzf # fast file search
    ripgrep # fast text search
    lnav

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
    wdisplays # Дисплей менеджер

    # Web & Terminal
    ueberzugpp # pic in terminal
    w3m # web-browser in terminal

    # Archiving
    file-roller # визуальный архиватор
    zip
    unzip
    p7zip
    unrar
    # kdenlive
    # jetbrains.pycharm-professional
    # jre8
    # qemu
    # quickemu

  ] ++ [
    # AI — официальная сборка Antigravity CLI; запускается командой agy.
    antigravityCliPackage

    # AI — официальный flake opencode, обновляется через `nix flake update opencode`.
    opencodePackage

    # Telegram — из nixpkgs-unstable, чтобы не отставать от stable upstream.
    pkgs-unstable.telegram-desktop
  ];
}
