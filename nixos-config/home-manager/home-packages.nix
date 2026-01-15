{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  #Общие программы - будут установлены для всех hosts

  home.packages = with pkgs; [
    # Packages in each category are sorted alphabetically
    alacritty # Терминал
    wofi # Лаунчер
    nixpkgs-fmt
    dunst
    libnotify
    waybar
    wl-clipboard

    # Screenshot
    grim
    slurp
    swappy

    wev
    pamixer
    brightnessctl
    tree
    ranger
    xclip
    neofetch
    mc
    woeusb
    ntfs3g # для работы с флешкой
    gnupg

    # # Desktop apps
    # anki
    # code-cursor
    # imv
    # mpv
    # obs-studio
    # obsidian
    # pavucontrol
    # teams-for-linux
    # telegram-desktop
    # vesktop
    #
    # # CLI utils
    # bc
    # bottom
    # brightnessctl
    cliphist
    # ffmpeg
    # ffmpegthumbnailer
    # fzf
    # git-graph
    grimblast
    # htop
    # hyprpicker
    # ntfs3g
    # mediainfo
    # microfetch
    # playerctl
    # ripgrep
    # showmethekey
    # silicon
    # udisks
    # ueberzugpp
    # unzip
    # w3m
    # wget
    # wtype
    # yt-dlp
    # zip
    #
    # # Coding stuff
    # openjdk23
    # nodejs
    # python311
    #
    # # WM stuff
    libsForQt5.xwaylandvideobridge
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    #
    # # Other
    # bemoji
    # nix-prefetch-scripts
  ];
}
