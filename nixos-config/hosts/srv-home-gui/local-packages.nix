{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    firefox
    git
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
