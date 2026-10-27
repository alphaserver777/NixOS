{ config, lib, pkgs, user, ... }:

let
  cfg = config.services.mantaray;
  package = pkgs.callPackage ../../packages/mantaray.nix { };
in
{
  options.services.mantaray.enable = lib.mkEnableOption "MantaRay VPN";

  config = lib.mkMerge [
    {
      services.mantaray.enable = lib.mkDefault
        (config.programs.hyprland.enable || config.services.xserver.enable);
    }
    (lib.mkIf cfg.enable {
      environment.systemPackages = [ package ];
      users.groups.mantaray-vpn = { };
      users.users.${user}.extraGroups = [ "mantaray-vpn" ];

      # Задача 042: параметры защиты и права из службы производителя.
      systemd.services."com.mantaray.vpn" = {
        description = "MantaRay VPN Linux tunnel service";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.iproute2 pkgs.nftables pkgs.systemd pkgs.util-linux pkgs.coreutils ];
        serviceConfig = {
          Type = "simple";
          User = "root";
          Group = "mantaray-vpn";
          ExecStart = "${package}/opt/mantaray/libexec/mantaray-core-service";
          Restart = "on-failure";
          RestartSec = "2s";
          RuntimeDirectory = "mantaray-vpn";
          RuntimeDirectoryMode = "0770";
          CacheDirectory = "mantaray-vpn";
          CacheDirectoryMode = "0700";
          NoNewPrivileges = true;
          CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_SYS_PTRACE" "CAP_DAC_READ_SEARCH" ];
          AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_SYS_PTRACE" "CAP_DAC_READ_SEARCH" ];
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          RestrictRealtime = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
        };
      };
    })
  ];
}
