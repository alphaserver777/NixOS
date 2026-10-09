{ config, lib, pkgs, hostname, ... }:

let
  is-x-disk = hostname == "x-disk";
  gdrive-dir = "${config.home.homeDirectory}/Google-Drive";
  rclone-config = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
in
{
  sops = lib.mkIf is-x-disk {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    secrets."rclone-gdrive-config" = {
      path = rclone-config;
    };
  };

  systemd.user.services.rclone-gdrive-mount = lib.mkIf is-x-disk {
    Unit = {
      Description = "Rclone mount for Google Drive";
      After = [ "network-online.target" "sops-nix.service" ];
      Wants = [ "network-online.target" ];
      Requires = [ "sops-nix.service" ];
    };

    Service = {
      Type = "simple";
      # Задача 014: rclone сам отключает FUSE при SIGTERM. Обычный
      # fusermount3 из Nix не имеет прав привилегированной обёртки NixOS.
      Environment = "PATH=/run/wrappers/bin:${lib.makeBinPath [ pkgs.fuse3 pkgs.coreutils ]}";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${gdrive-dir}";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount gdrive: ${gdrive-dir} \
          --config ${rclone-config} \
          --vfs-cache-mode writes
      '';
      SuccessExitStatus = "143";
      TimeoutStopSec = 120;
      Restart = "on-failure";
      RestartSec = 30;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
