{ lib, pkgs, hostname, ... }:
{
  config = lib.mkIf (hostname == "x-disk") {
    # Задача 014: rsyslog записывает эти файлы, но не создаёт правил ротации.
    services.logrotate = {
      enable = true;
      settings.syslog = {
        files = [ "/var/log/messages" "/var/log/warn" "/var/log/mail" "/var/log/dhcpd" ];
        frequency = "daily";
        maxsize = "32M";
        rotate = 14;
        missingok = true;
        notifempty = true;
        compress = true;
        delaycompress = true;
        create = "0640 root root";
        sharedscripts = true;
        postrotate = ''
          if ${pkgs.systemd}/bin/systemctl is-active --quiet syslog.service; then
            ${pkgs.systemd}/bin/systemctl kill --kill-whom=main --signal=HUP syslog.service
          fi
        '';
      };
    };
    systemd.timers.logrotate.timerConfig.OnCalendar = lib.mkForce "hourly";
    services.journald.extraConfig = ''
      SystemMaxUse=768M
      SystemKeepFree=2G
    '';
  };
}
