{ pkgs, ... }: {
  programs.neovim = {
    enable = true;

    extraPackages = with pkgs; [
      lua-language-server
        python311Packages.python-lsp-server
        nixd
        vimPlugins.nvim-treesitter-parsers.hyprlang
        fd
        ripgrep
    ];

    plugins = with pkgs.vimPlugins; [
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

      -- Catppuccin тема
      require("catppuccin").setup({
          flavour = "mocha",
          transparent_background = false,
          integrations = {
          alpha = true,
          cmp = true,
          gitsigns = true,
          telescope = true,
          which_key = true,
          bufferline = true,
          },
          })
    vim.cmd.colorscheme "catppuccin"

      -- Flash.nvim
      require("flash").setup({
          jump = { autojump = true },
          modes = { search = { enabled = true } },
          })
    vim.keymap.set({"n","x","o"}, "<leader>s", function()
        require("flash").jump()
        end, { desc = "Flash jump" })

      -- Telescope
      require("telescope").setup({
          defaults = {
          mappings = {
          i = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
          },
          },
          },
          })
    local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })

      -- Lualine
      require("lualine").setup({
          options = {
          icons_enabled = true,
          theme = "catppuccin",
          },
          sections = {
          lualine_a = {"mode"},
          lualine_b = {"branch", "diff", "diagnostics"},
          lualine_c = {"filename"},
          lualine_x = {"filesize", "filetype"},
          lualine_y = {"progress"},
          lualine_z = {"location"},
          },
          extensions = {},
          })

    -- Bufferline
      require("bufferline").setup({
          options = {
          numbers = "buffer_id",
          indicator = { style = "underline" },
          diagnostics = "nvim_lsp",
          separator_style = "slant",
          show_buffer_close_icons = true,
          show_close_icon = false,
          }
          })
    vim.keymap.set("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
      vim.keymap.set("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
      vim.keymap.set("n", "<leader>bd", "<Cmd>BufferLineClose<CR>", { desc = "Close buffer" })

      -- Neo-tree
      require("neo-tree").setup({
          close_if_last_window = true,
          filesystem = {
          filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          },
          },
          window = {
          position = "left",
          width = 30,
          },
          })

    -- 🔑 Удобные хоткеи для переключения Neo-tree <-> редактор
      -- Фокус в Neo-tree
      vim.keymap.set("n", "<leader>1", function()
          require("neo-tree.command").execute({ action = "focus" })
          end, { desc = "Focus Neo-tree" })

      -- Вернуться в редактор
      vim.keymap.set("n", "<leader>2", "<C-w>p", { desc = "Focus editor window" })

      -- Gitsigns
      require("gitsigns").setup({
          signs = {
          add          = { text = "+" },
          change       = { text = "│" },
          delete       = { text = "_" },
          topdelete    = { text = "‾" },
          changedelete = { text = "~" },
          },
          current_line_blame = true,
          })
    '';
  };
               }
