{ pkgs, stateVersion, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
  ];

  environment.systemPackages = [ pkgs.home-manager ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      public = {
        path = "/home/admsys";
        browseable = "yes";
        "read only" = "no";
        "create mask" = "0664";
        "directory mask" = "0775";
        "valid users" = "admsys";
      };
    };
  };

  # Enable polkit and udisks2 service
  security.polkit.enable = true;
  services.udisks2.enable = true;

  # Manually add polkit rule for old NixOS versions
  environment.etc."polkit-1/rules.d/50-udisks.rules".text = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.udisks2.filesystem-mount-system" &&
            subject.isInGroup("wheel")) {
            return polkit.Result.YES;
        }
    });
  '';

}
