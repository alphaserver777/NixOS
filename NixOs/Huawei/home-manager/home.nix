{ config, pkgs, ... }: {

  imports = [
      ./modules
      ./home-packages.nix

  ];

  home = {
    username = "admsys";
    homeDirectory = "/home/admsys";
    stateVersion = "25.05";
  };
  programs.bash = {
    enable = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ./";
      homebuild = "home-manager switch --flake ./";
    };
  };
  
}
	

