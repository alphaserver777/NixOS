{ pkgs, ... }:

{
  imports = [
    ../displayManager.nix
    ../hyprland.nix
  ];

  security.polkit.enable = true;
  services.libinput.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  fonts.packages = with pkgs; [
    dejavu_fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
  ];
}
