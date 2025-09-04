{ pkgs, ... }: {
  programs.neovim = {
    enable = true;

    extraPackages = with pkgs; [
      lua-language-server
        python311Packages.python-lsp-server
        nixd
        vimPlugins.nvim-treesitter-parsers.hyprlang
    ];

    plugins = with pkgs.vimPlugins; [
      gruvbox-material
        nerdtree
        nvim-web-devicons
        which-key-nvim
        vim-fugitive
        comment-nvim
        vim-autoformat
        flash-nvim
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

      " Горячая клавиша для переключения NerdTree
      map <C-n> :NERDTreeToggle<CR>

      " Автоматическое форматирование при сохранении
      autocmd BufWritePre * Autoformat

      " Переключение между окнами без плагина
      nnoremap <C-h> <C-w>h
      nnoremap <C-j> <C-w>j
      nnoremap <C-k> <C-w>k
      nnoremap <C-l> <C-w>l
      '';

    extraLuaConfig = ''
      -- назначаем Space как <leader>
      vim.g.mapleader = " "

      require("flash").setup({
          jump = {
          autojump = true,
          },
          modes = {
          search = {
          enabled = true,
          },
          },
          })

    -- теперь вызвать flash можно через <Space>s
      vim.keymap.set({"n","x","o"}, "<leader>s", function()
          require("flash").jump()
          end, { desc = "Flash jump" })
      '';
  };
               }
