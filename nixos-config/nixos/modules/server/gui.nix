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
}
