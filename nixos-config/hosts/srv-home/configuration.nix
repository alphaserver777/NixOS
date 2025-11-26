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

  # Add a delay before NetworkManager starts to allow the WiFi device to initialize.
  systemd.services.NetworkManager.preStart = ''
    ${pkgs.coreutils}/bin/sleep 10
  '';

  environment.systemPackages = [ pkgs.home-manager ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;
}

