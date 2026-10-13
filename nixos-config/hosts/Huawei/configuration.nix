{ lib, pkgs, stateVersion, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./audio.nix
    ./local-packages.nix
    ../../nixos/modules
  ];

  hardware.enableAllFirmware = true;
  # Задача 025: общий модуль оставляет адаптер выключенным после загрузки.
  hardware.bluetooth.powerOnBoot = lib.mkForce true;

  environment.systemPackages = [ pkgs.home-manager pkgs.qemu pkgs.alsa-utils ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  services.samba = {
    enable = true;
    settings = {
      public = {
        path = "/home/admsys/PublicShare";
        browseable = "yes";
        "read only" = "no";
        "create mask" = "0664";
        "directory mask" = "0775";
        "valid users" = "admsys";
      };
    };
  };
}
