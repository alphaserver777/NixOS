{ pkgs, stateVersion, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
  ];

  hardware.enableAllFirmware = true;

  boot.extraModprobeConfig = ''
    options snd_soc_sof_es8336 quirk=160
  '';

  environment.systemPackages = [ pkgs.home-manager pkgs.qemu pkgs.alsa-utils ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  services.pipewire.wireplumber.extraConfig."51-huawei-speaker-priority" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          {
            "node.name" = "alsa_output.pci-0000_00_1f.3-platform-sof-essx8336.HiFi__Speaker__sink";
          }
        ];
        actions.update-props = {
          "priority.session" = 2000;
          "priority.driver" = 2000;
        };
      }
    ];
  };

  services.pipewire.wireplumber.extraConfig."52-disable-stream-target-restore" = {
    "wireplumber.settings" = {
      "node.stream.restore-target" = false;
      "node.restore-default-targets" = false;
    };
  };

  systemd.services.fix-sound-essx8336 = {
    description = "Set ALSA mixer controls for sof-essx8336";
    after = [ "systemd-udev-settle.service" "sound.target" ];
    wants = [ "systemd-udev-settle.service" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      for _ in $(${pkgs.coreutils}/bin/seq 1 30); do
        if ${pkgs.alsa-utils}/bin/amixer -c sofessx8336 info >/dev/null 2>&1; then
          break
        fi
        ${pkgs.coreutils}/bin/sleep 1
      done

      ${pkgs.alsa-utils}/bin/amixer -c sofessx8336 cset name='Left Headphone Mixer Left DAC Switch' on
      ${pkgs.alsa-utils}/bin/amixer -c sofessx8336 cset name='Right Headphone Mixer Right DAC Switch' on
      ${pkgs.alsa-utils}/bin/amixer -c sofessx8336 cset name='Headphone Switch' on
      ${pkgs.alsa-utils}/bin/amixer -c sofessx8336 cset name='Headphone Playback Volume' 80%
      ${pkgs.alsa-utils}/bin/amixer -c sofessx8336 cset name='Speaker Switch' on
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
