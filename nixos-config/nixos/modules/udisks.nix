{ pkgs, user, ... }:

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

    systemd.user.services.udiskie = {
      Unit = {
        Description = "Removable media automounter";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.udiskie}/bin/udiskie --no-tray --automount --notify";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
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
