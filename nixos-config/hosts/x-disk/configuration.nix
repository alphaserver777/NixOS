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

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };

  programs.virt-manager.enable = true;
}
