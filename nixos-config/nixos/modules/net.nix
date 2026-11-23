{ pkgs, pkgs-unstable, ... }:

let
  netwatch = pkgs.callPackage ../../packages/netwatch-nixos.nix {
    upstream = pkgs-unstable.netwatch;
  };
in
{
  networking.networkmanager.enable = true;
  environment.systemPackages = [
    pkgs.trippy
    pkgs.rustnet
    netwatch
  ];
  networking.networkmanager.dispatcherScripts = [{
    source = pkgs.writeText "add-static-route" ''
      #!/bin/sh
      # $1 is the interface name, $2 is the action
      if [ "$1" = "eno1" ] && [ "$2" = "up" ]; then
        /run/current-system/sw/bin/ip route add 172.17.12.132/32 via 10.152.34.1 dev eno1
      fi
    '';
  }];
}