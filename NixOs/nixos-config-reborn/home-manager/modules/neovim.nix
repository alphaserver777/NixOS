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
        tree-sitter
    ];

# фиксим устаревший pynvim
    extraPython3Packages = ps: with ps; [ pynvim ];

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
        bufdelete-nvim

# только нужные treesitter-парсеры
        (nvim-treesitter.withPlugins (p: [
                                      p.go
                                      p.python
                                      p.nix
        ]))
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
          theme = "auto",
          },
          sections = {
          lualine_a = {"mode"},
          lualine_b = {"branch", "diff", "diagnostics"},
          lualine_c = {"filename"},
          lualine_x = {"filesize", "filetype"},
          lualine_y = {"progress"},
          lualine_z = {"location"},
          },
          extensions = {"neo-tree"},
          })

    -- Bufferline
      require("bufferline").setup({
          options = {
          numbers = "ordinal", -- показывает порядковые номера (1,2,3...)
          indicator = { style = "underline" },
          diagnostics = "nvim_lsp",
          separator_style = "slant",
          show_buffer_close_icons = true,
          show_close_icon = false,
          }
          })

    -- 🔑 Быстрая навигация и закрытие буферов
      for i = 1, 9 do
        -- Переключение: <leader> + цифра
          vim.keymap.set("n", "<leader>" .. i,
              "<Cmd>BufferLineGoToBuffer " .. i .. "<CR>",
              { desc = "Go to buffer " .. i })

    -- Закрытие: <leader>b + цифра (без выхода из Neovim)
      vim.keymap.set("n", "<leader>b" .. i, function()
          vim.cmd("BufferLineGoToBuffer " .. i)
          vim.cmd("Bdelete")  -- ✅ безопасное закрытие
          end, { desc = "Close buffer " .. i })
      end

      -- Стандартные переключения
      vim.keymap.set("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })
      vim.keymap.set("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous buffer" })
      vim.keymap.set("n", "<leader>bd", "<Cmd>Bdelete<CR>", { desc = "Close current buffer safely" })

      -- Neo-tree
      require("neo-tree").setup({
          close_if_last_window = true,
          window = {
          position = "left",
          width = 30,
          mappings = {
          ["<space>"] = "none", -- отключаем стандартное действие пробела
          ["<CR>"] = "open",    -- Enter = открыть файл
          },
          },
          filesystem = {
          filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          },
          follow_current_file = { enabled = true },
          hijack_netrw_behavior = "open_default",
          },
          buffers = {
          follow_current_file = { enabled = true },
          },
          event_handlers = {
            {
              event = "file_opened",
              handler = function(_)
                -- Закрывать Neo-tree при открытии файла (чтобы редактор был на весь экран)
                require("neo-tree.command").execute({ action = "close" })
                end
            },
            {
              event = "file_hovered",
              handler = function(file)
                -- Автоматически показывать предпросмотр файла при наведении
                require("neo-tree.sources.common.preview").preview(file)
                end
            },
          },
      })

    -- 🔑 Удобные хоткеи для Neo-tree
      -- Переключатель: <leader><Tab>
      vim.keymap.set("n", "<leader><Tab>", function()
          if vim.bo.filetype == "neo-tree" then
          vim.cmd.wincmd("p") -- вернуться в предыдущий буфер/окно
          else
          require("neo-tree.command").execute({ action = "focus" })
          end
          end, { desc = "Toggle between Neo-tree and editor" })

      -- Просто открыть/закрыть Neo-tree
      vim.keymap.set("n", "<leader>e", function()
          require("neo-tree.command").execute({ toggle = true })
          end, { desc = "Toggle Neo-tree" })

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
    vim.keymap.set('n', ']g', require('gitsigns').next_hunk, { desc = 'Go to next git hunk' })
      vim.keymap.set('n', '[g', require('gitsigns').prev_hunk, { desc = 'Go to previous git hunk' })

      -- Автоматически открывать Neo-tree при запуске Neovim
      vim.api.nvim_create_autocmd("UIEnter", {
          callback = function()
          -- Ждем немного чтобы все плагины загрузились
          vim.defer_fn(function()
              require("neo-tree.command").execute({ action = "show" })
              end, 100)
          end,
          once = true,
          })
    '';
  };
               }
