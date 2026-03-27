{ hostname, stateVersion, ... }:

{
  imports = [
    ../srv-home-min/hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules/server
    ../../nixos/modules/audio.nix
    ../../nixos/modules/server/gui.nix
  ];

  hardware.enableAllFirmware = true;

  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0 11n_disable=8 swcrypto=1
    options rtw88_pci disable_aspm=1
  '';
  boot.kernelParams = [ "pcie_aspm=off" ];
  networking.networkmanager.wifi.powersave = false;

  systemd.services.NetworkManager.preStart = ''
    /run/current-system/sw/bin/sleep 10
  '';

  networking.hostName = hostname;

  system.stateVersion = stateVersion;
}
