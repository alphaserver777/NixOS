{ pkgs, ... }:
{
  systemd.user.services.nix-gc-user = {
    Unit.Description = "Nix GC: очистка профилей пользователя";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 20d";
    };
  };

  systemd.user.timers.nix-gc-user = {
    Unit.Description = "Ежемесячная очистка профилей Nix пользователя";
    Timer = {
      OnCalendar = "monthly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
