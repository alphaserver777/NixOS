{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.clash-verge-rev ];

  # Привилегированная служба нужна Clash Verge для режима TUN.
  # Графическое приложение при этом продолжает работать от обычного пользователя.
  systemd.services.clash-verge-service = {
    description = "Служба Clash Verge для режима TUN";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.clash-verge-rev}/bin/clash-verge-service";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
