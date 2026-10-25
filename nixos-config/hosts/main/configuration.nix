{ pkgs, stateVersion, hostname, user, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ./clipboard.nix
    ../../nixos/modules
  ];

  environment.systemPackages = [ pkgs.home-manager ];

  # Сохраняем свободный драйвер видеокарты, используемый на main.
  hardware.graphics.enable = true;

  networking.hostName = hostname;

  system.stateVersion = stateVersion;
}
