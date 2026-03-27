{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    firefox
    git
    iperf3
    mpv
    mtr
    networkmanagerapplet
    neovim
    pavucontrol
    ripgrep
    speedtest-cli
    tint2
    unzip
    xdg-utils
    xterm
    zip
  ];
}
