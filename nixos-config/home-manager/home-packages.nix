{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  #Общие программы - будут установлены для всех hosts

  home.packages = with pkgs; [
    # Packages in each category are sorted alphabetically
    alacritty # Терминал
    nixpkgs-fmt
    dnsutils # nslookup
    libnotify
    wl-clipboard

    # Screenshot
    grim
    slurp

    wev
    pamixer
    playerctl
    brightnessctl
    btop
    tree
    rclone
    sops #encrypted in nixos
    xclip
    fastfetch
    woeusb
    xmind
    ntfs3g # для работы с флешкой
    gnupg

    # # Desktop apps
    # anki
    # code-cursor
    gnome-clocks
    # imv
    # mpv
    obs-studio
    # obsidian
    # pavucontrol
    super-productivity
    # teams-for-linux
    # telegram-desktop
    # vesktop
    #
    # # CLI utils
    # bc
    # bottom
    # brightnessctl
    cliphist
    ffmpeg
    # ffmpegthumbnailer
    # fzf
    # git-graph
    grimblast
    # htop
    # hyprpicker
    # ntfs3g
    # mediainfo
    # microfetch
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
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    #
    # # Other
    # bemoji
    # nix-prefetch-scripts
  ];
}
