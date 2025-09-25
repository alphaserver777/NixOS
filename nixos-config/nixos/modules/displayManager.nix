{ pkgs, ... }:

{
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.defaultSession = "hyprland";
  services.displayManager.sessionPackages = [ pkgs.hyprland ];
}
