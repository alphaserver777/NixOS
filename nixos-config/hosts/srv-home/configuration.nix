{ pkgs, stateVersion, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
  ];

  # Ensure all firmware is available, especially for WiFi.
  hardware.enableAllFirmware = true;

  # Disable WiFi power saving and other problematic features to prevent intermittent connection drops
  boot.extraModprobeConfig = "options iwlwifi power_save=0 11n_disable=8 swcrypto=1";

  # Add a delay before NetworkManager starts to allow the WiFi device to initialize.
  systemd.services.NetworkManager.preStart = ''
    ${pkgs.coreutils}/bin/sleep 10
  '';

  environment.systemPackages = [ pkgs.home-manager ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  # Mount the /dev/sdb1 partition at /mnt/DATA
  # For more stability, it's recommended to use the partition's UUID.
  # You can find the UUID by running: sudo blkid /dev/sdb1
  fileSystems."/mnt/DATA" = {
    device = "/dev/sdb1";
    fsType = "auto";
    options = [ "defaults" ];
  };
}

