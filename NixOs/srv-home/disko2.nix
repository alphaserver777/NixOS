{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";  # Или /dev/nvme0n1 для NVMe
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # 1. Раздел ESP (UEFI) - 512M
            boot = {
              type = "EF00";       # Тип EFI
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";  # Важно для UEFI!
                extraArgs = [ "-n" "EFI" ];  # Метка тома
              };
            };

            # 2. Swap - 4G (или больше для гибернации)
            swap = {
              size = "4G";
              content = {
                type = "swap";
                resumeDevice = true;  # Для гибернации
              };
            };

            # 3. Корневой раздел (/) - 50G
            root = {
              size = "50G";
              content = {
                type = "filesystem";
                format = "ext4";     # Или "btrfs"
                mountpoint = "/";
                extraArgs = [ "-L ROOT" ];
              };
            };

            # 4. Домашний раздел (/home) - всё оставшееся (~91.5G)
            home = {
              size = "100%";         # Заберёт оставшееся место
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/home";
                extraArgs = [ "-L HOME" ];
              };
            };
          };
        };
      };
    };
  };
}
