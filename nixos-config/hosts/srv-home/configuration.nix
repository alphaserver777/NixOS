{ pkgs, stateVersion, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
  ];

  # Disable WiFi power saving to prevent intermittent connection drops
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0
  '';

  environment.systemPackages = [ pkgs.home-manager ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;
}

