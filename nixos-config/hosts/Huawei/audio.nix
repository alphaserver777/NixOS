{ config, lib, pkgs, ... }:

{
  # Задача 021: ноутбук BOD-WXX9 с ES8336. LTS-ветка вместо обновлений
  # Zen до новых основных версий; HDMI, динамики и DMIC требуют SOF.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;
  boot.extraModulePackages = [
    (pkgs.callPackage ../../packages/sof-es8336-gpio.nix {
      kernel = config.boot.kernelPackages.kernel;
    })
  ];
  boot.initrd.availableKernelModules = [ "snd_soc_sof_es8336" ];
  boot.extraModprobeConfig = ''
    options snd_intel_dspcfg dsp_driver=3
    options snd_soc_sof_es8336 quirk=160
  '';

  services.pipewire.wireplumber.extraConfig."51-huawei-speaker-priority" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "node.name" = "~alsa_.*sof-essx8336.*"; }
        ];
        actions.update-props."session.suspend-timeout-seconds" = 0;
      }
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
      # Задача 024: 80% округляется до -12 dB; 100% даёт штатные 0 dB.
      ${pkgs.alsa-utils}/bin/amixer -c sofessx8336 cset name='Headphone Playback Volume' 100%
      ${pkgs.alsa-utils}/bin/amixer -c sofessx8336 cset name='Speaker Switch' on
    '';
    serviceConfig.Type = "oneshot";
  };
}
