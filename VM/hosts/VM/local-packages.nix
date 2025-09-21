{ pkgs, ... }: {
  # Частные программы узла
  environment.systemPackages = with pkgs; [
    #amnezia-vpn
    home-manager
    neovim
  ];
}
