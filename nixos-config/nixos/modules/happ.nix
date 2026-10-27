{ pkgs, ... }:

let
  package = pkgs.callPackage ../../packages/happ.nix { };
in {
  environment.systemPackages = [ package ];

  # Задача 044: аналог службы производителя, без запуска установщика Debian.
  # Запуск службы сам по себе не включает соединение.
  systemd.services.happd = {
    description = "Служба управления туннелем Happ";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    path = with pkgs; [
      iproute2 nftables iptables systemd util-linux coreutils procps iputils
    ];
    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "root";
      ExecStart = "${package}/bin/happd";
      StateDirectory = "happd";
      StateDirectoryMode = "0700";
      # При несовпадении версий клиент просит службу завершиться с кодом 0.
      Restart = "always";
      RestartSec = "5s";
      TimeoutStopSec = "10s";
      KillMode = "mixed";
    };
  };
}
