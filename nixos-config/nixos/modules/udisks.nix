{ config, pkgs, ... }:

{
  # Enable the udisks2 service for auto-mounting removable media.
  services.udisks2.enable = true;
}
