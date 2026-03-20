{ pkgs, stateVersion, hostname, user, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
  ];

  environment.systemPackages = [ pkgs.home-manager ];

  networking.hostName = hostname;

  nixpkgs.config.permittedInsecurePackages = [
    "beekeeper-studio-5.1.5"
  ];

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
}
