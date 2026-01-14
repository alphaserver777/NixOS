{ pkgs, ... }:
let
  flameshot-wayland = pkgs.flameshot.overrideAttrs (oldAttrs: {
    # Enable grim for Wayland support as per documentation
    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [ "-DUSE_WAYLAND_GRIM=ON" ];
    buildInputs = (oldAttrs.buildInputs or []) ++ [ pkgs.grim pkgs.slurp ];
  });
in
{
  # XDG Portal for screenshots
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # Install the custom-built flameshot and its runtime dependencies
  home.packages = [
    flameshot-wayland
    pkgs.grim
    pkgs.slurp
    pkgs.swappy
  ];
}
