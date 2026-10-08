{ pkgs-unstable, ... }:

{
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.package = pkgs-unstable.virtualbox;
}
