{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    git
    google-chrome
    iperf3
    mpv
    mtr
    neovim
    pavucontrol
    ripgrep
    speedtest-cli
    unzip
    xdg-utils
    zip
  ];
}
