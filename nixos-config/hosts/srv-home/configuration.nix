{ pkgs, stateVersion, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
  ];

  # Ensure all firmware is available, especially for WiFi.
  hardware.enableAllFirmware = true;

  # Disable WiFi power saving to prevent intermittent connection drops
  boot.extraModprobeConfig = "options iwlwifi power_save=0";

  # Wait for the WiFi device to be ready before attempting to connect.
  networking.networkmanager.wait-for-device-timeout = 30;

  environment.systemPackages = [ pkgs.home-manager ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;
}

