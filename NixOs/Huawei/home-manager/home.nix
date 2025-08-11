{ config, pkgs, ... }: {
	home = {
		username = "root";
		homeDirectory = "/root";
		stateVersion = "25.05";
	};
	programs.bash = {
		enable = true;
		shellAliases = {
			rebuild = "sudo nixos-rebuild switch";
		};
	};
	programs.neovim = {
		enable = true;
    		plugins = with pkgs.vimPlugins; [
      			gruvbox-material
      			nerdtree
    		];
		extraConfig = ''
			set tabstop=2 # Табуляция
			set expandtab 
			set number
      set hlsearch
      set incsearch
		'';
  	};

	programs.git = {
		enable = true;
		userName = "crypto_mrx";
		userEmail = "maksim.ilonov@yandex.ru";
	};
}	

