{ pkgs, ... }: {
  programs.neovim = {
    enable = true;

    extraPackages = with pkgs; [
      lua-language-server
        python311Packages.python-lsp-server
        nixd
        vimPlugins.nvim-treesitter-parsers.hyprlang
# Добавляем fd и ripgrep для Telescope
        fd
        ripgrep
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
# Добавляем Telescope
        telescope-nvim
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

      ---
      -- Настройка и горячие клавиши для Telescope
      ---
      require('telescope').setup({
          defaults = {
          mappings = {
          i = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
          },
          },
          },
          })

    -- Горячие клавиши
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })
      '';
  };
               }
