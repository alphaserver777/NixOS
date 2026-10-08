{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    btop
    git
    iperf3
    mtr
    neovim
    ripgrep
    speedtest-cli
    unzip
    zip
  ];
}
