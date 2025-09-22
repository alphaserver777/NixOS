{ pkgs, stateVersion, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
  ];

  hardware.enableAllFirmware = true;

  environment.systemPackages = [ pkgs.home-manager pkgs.qemu pkgs.alsa-utils ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  systemd.services.fix-sound-essx8336 = {
    description = "Set ALSA mixer controls for sof-essx8336";
    after = [ "sound.target" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.alsa-utils}/bin/amixer -c 0 cset name='Left Headphone Mixer Left DAC Switch' on
      ${pkgs.alsa-utils}/bin/amixer -c 0 cset name='Right Headphone Mixer Right DAC Switch' on
      ${pkgs.alsa-utils}/bin/amixer -c 0 cset name='Headphone Switch' on
      ${pkgs.alsa-utils}/bin/amixer -c 0 cset numid=1 80%
      ${pkgs.alsa-utils}/bin/amixer -c 0 cset name='Speaker Switch' on
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };

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

