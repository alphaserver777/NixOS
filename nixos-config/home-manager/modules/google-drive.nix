{ config, pkgs, ... }:

let
  # Define the mount point directory in a variable for easy reuse.
  gdrive-dir = "${config.home.homeDirectory}/Google-Drive";
in
{
  systemd.user.services.rclone-gdrive-mount = {
    Unit = {
      Description = "Rclone mount for Google Drive";
      # Start after the network is online
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      # Create the mount point directory before starting the service
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${gdrive-dir}";
      # The command to mount the drive
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount gdrive: ${gdrive-dir} \
          --config ${config.home.homeDirectory}/.config/rclone/rclone.conf \
          --vfs-cache-mode writes
      '';
      # The command to unmount the drive
      ExecStop = "${pkgs.fuse}/bin/fusermount -u ${gdrive-dir}";
      Restart = "on-failure";
      RestartSec = 10;
    };

    Install = {
      # Start the service automatically on user login
      WantedBy = [ "default.target" ];
    };
  };
}
