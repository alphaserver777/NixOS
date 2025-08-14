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
  
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      gruvbox-material
      nerdtree
      nvim-web-devicons
      which-key-nvim
      vim-fugitive
      comment-nvim
    ];
    extraConfig = ''
				set tabstop=2
				set expandtab
				set shiftwidth=2
				set number
				set relativenumber
				set hlsearch
				set incsearch
				set clipboard=unnamedplus
    '';
  };



}
	

