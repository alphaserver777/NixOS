{ pkgs
, ...
}: {
  programs.neovim = {
    enable = true;

    extraPackages = with pkgs; [
      lua-language-server
      python311Packages.python-lsp-server
      nixd
      vimPlugins.nvim-treesitter-parsers.hyprlang
      fd
      ripgrep
      tree-sitter
    ];

    # фиксим устаревший pynvim
    extraPython3Packages = ps: with ps; [ pynvim ];

    plugins = with pkgs.vimPlugins; [
      alpha-nvim
      catppuccin-nvim
      neo-tree-nvim
      nvim-web-devicons
      which-key-nvim
      vim-fugitive
      comment-nvim
      vim-autoformat
      flash-nvim
      telescope-nvim
      lualine-nvim
      bufferline-nvim
      gitsigns-nvim
      bufdelete-nvim

      # только нужные treesitter-парсеры
      (nvim-treesitter.withPlugins (p: [
        p.go
        p.python
        p.nix
      ]))
    ];
  };

  # Подключаем конфигурацию как обычные dotfiles
  home.file.".config/nvim" = {
    source = ./.;
    recursive = true;
  };
}
