{ pkgs, ... }: {
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
