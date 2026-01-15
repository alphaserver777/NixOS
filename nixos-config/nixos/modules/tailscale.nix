{ config, pkgs, lib, hostname, ... }:

lib.mkMerge [
  (lib.mkIf (hostname != "x-disk") {
    services.tailscale.enable = true;
  })
  (lib.mkIf (hostname == "x-disk") {
    services.tailscale.enable = true;
    services.tailscale.extraUpFlags = [
      "--accept-dns=false"
      "--accept-routes=false"
    ];
  })
]
