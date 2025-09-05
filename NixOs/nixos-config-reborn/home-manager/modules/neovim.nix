{ pkgs, ... }: {
  programs.neovim = {
    enable = true;

    extraPackages = with pkgs; [
      lua-language-server
        python311Packages.python-lsp-server
        nixd
        vimPlugins.nvim-treesitter-parsers.hyprlang
# Добавьте эти пакеты для nvim-cmp
        ripgrep # Используется cmp-grep, если нужен
        stylua # Форматтер для Lua
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
# Добавьте nvim-cmp и его зависимости
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        luasnip
        friendly-snippets
        nvim-lspconfig
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
      -- Конфигурация nvim-cmp
      ---
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      cmp.setup({
          snippet = {
          expand = function(args)
          luasnip.lsp_expand(args.body)
          end,
          },
          window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
          },
          mapping = cmp.mapping.preset.insert({
              ['<C-b>'] = cmp.mapping.scroll_docs(-4),
              ['<C-f>'] = cmp.mapping.scroll_docs(4),
              ['<C-Space>'] = cmp.mapping.complete(),
              ['<C-e>'] = cmp.mapping.abort(),
              ['<CR>'] = cmp.mapping.confirm({ select = true }),
              }),
          sources = cmp.config.sources({
              { name = 'nvim_lsp' },
              { name = 'luasnip' },
              { name = 'buffer' },
              { name = 'path' },
              }),
      })

    -- Использование nvim-cmp в командной строке
      cmp.setup.cmdline({ '/', '?' }, {
          mapping = cmp.mapping.preset.cmdline(),
          sources = {
          { name = 'buffer' }
          }
          })

    -- Использование nvim-cmp для команд
      cmp.setup.cmdline(':', {
          mapping = cmp.mapping.preset.cmdline(),
          sources = cmp.config.sources({
              { name = 'path' }
              }, {
              { name = 'cmdline' }
              })
          })

    ---
      -- Конфигурация nvim-lspconfig
      ---
      local lspconfig = require('lspconfig')

      -- Включаем nvim-cmp для всех LSP-серверов
      local on_attach = function(client, bufnr)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition', buffer = bufnr })
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'Go to references', buffer = bufnr })
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover', buffer = bufnr })
      end

      -- Настраиваем серверы
      lspconfig.pyright.setup({
          on_attach = on_attach,
          })

    -- ⚡️ ОБНОВЛЕННАЯ КОНФИГУРАЦИЯ ДЛЯ LUA_LS
      lspconfig.lua_ls.setup({
          on_attach = on_attach,
          settings = {
          Lua = {
          runtime = {
          version = 'LuaJIT'
          },
          diagnostics = {
          globals = { 'vim' }
          }
          }
          }
          })
    lspconfig.nixd.setup({
        on_attach = on_attach,
        })
    '';
  };
               }
