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
      ExecStartPre = "${pkgs.bash}/bin/bash -c \"${pkgs.fuse3}/bin/fusermount3 -uz ${gdrive-dir} >/dev/null 2>&1 || true; ${pkgs.coreutils}/bin/mkdir -p ${gdrive-dir}\"";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount gdrive: ${gdrive-dir} \
          --config ${rclone-config} \
          --vfs-cache-mode writes
      '';
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u ${gdrive-dir}";
      Restart = "on-failure";
      RestartSec = 10;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
