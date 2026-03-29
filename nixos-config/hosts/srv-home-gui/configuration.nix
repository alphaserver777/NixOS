{ hostname, pkgs, stateVersion, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules/boot.nix
    ../../nixos/modules/cron.nix
    ../../nixos/modules/env.nix
    ../../nixos/modules/kernel.nix
    ../../nixos/modules/net.nix
    ../../nixos/modules/nix.nix
    ../../nixos/modules/ssh.nix
    ../../nixos/modules/timezone.nix
    ../../nixos/modules/user.nix
    ../../nixos/modules/zram.nix
    ../../nixos/modules/amneziavpn.nix
    ../../nixos/modules/audio.nix
    ../../nixos/modules/server/shell.nix
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

  services.xserver = {
    enable = true;
    xkb.layout = "us,ru";
    xkb.options = "grp:alt_shift_toggle";

    displayManager.lightdm.enable = true;
    desktopManager.xfce.enable = true;
    desktopManager.xterm.enable = false;
  };

  services.displayManager.defaultSession = "xfce";

  security.polkit.enable = true;
  services.libinput.enable = true;

  fonts.packages = with pkgs; [
    pkgs.dejavu_fonts
    pkgs.noto-fonts
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-emoji
  ];

  environment.systemPackages = [ pkgs.xfce.xfce4-terminal ];
}
