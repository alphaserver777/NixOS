{
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig.pipewire."20-disable-x11-bell.conf" = {
      "context.modules" = [
        {
          name = "libpipewire-module-x11-bell";
          flags = [ "ifexists" "nofail" ];
          enable = false;
        }
      ];
    };
    wireplumber = {
      enable = true;
      extraConfig = {
        "10-disable-suspension" = {
          "wireplumber.settings" = {
            "monitor.alsa" = {
              "properties" = {
                "session.suspend-timeout-seconds" = 0;
              };
            };
          };
        };
      };
    };
  };
  hardware.alsa.enablePersistence = true;
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      SOUND_POWER_SAVE_ON_BAT = 0;
      SOUND_POWER_SAVE_ON_AC = 0;
    };
  };
}
