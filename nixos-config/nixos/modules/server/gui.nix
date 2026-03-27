{ pkgs, ... }:

{
  services.xserver = {
    enable = true;
    xkb.layout = "us,ru";
    xkb.options = "grp:alt_shift_toggle";

    displayManager.lightdm.enable = true;
    desktopManager.xterm.enable = false;
    windowManager.openbox.enable = true;
  };

  security.polkit.enable = true;

  services.libinput.enable = true;

  fonts.packages = with pkgs; [
    dejavu_fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
  ];

  environment.etc."xdg/openbox/autostart".text = ''
    xsetroot -solid "#20242b"
    tint2 &
    nm-applet &
    xterm -fa "DejaVu Sans Mono" -fs 10 -geometry 120x30+24+24 &
  '';
}
