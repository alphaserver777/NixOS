{ lib, pkgs, user, ... }:

{
  # Removable media integration for file managers and tray automounters.
  security.polkit.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    exfatprogs
    ntfs3g
  ];

  home-manager.users.${user} = {
    home.packages = [ pkgs.udiskie ];

    wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
      "udiskie --tray --smart-tray --automount --notify"
    ];
  };

  environment.etc."polkit-1/rules.d/50-udisks.rules".text = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.udisks2.filesystem-mount-system" &&
            subject.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    });
  '';
}
