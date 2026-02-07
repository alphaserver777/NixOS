{ config, pkgs, ... }:

{
  networking.networkmanager.enable = true;
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