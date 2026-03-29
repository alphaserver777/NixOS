{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-chrome
    pavucontrol
    xdg-utils
    btop
  ];
}
