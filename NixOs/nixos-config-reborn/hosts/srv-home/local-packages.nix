{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    gcc
    kdePackages.kdenlive
    vim
    git
    mc
    # jetbrains.pycharm-professional
    # jre8
    # qemu
    # quickemu
  ];
}
