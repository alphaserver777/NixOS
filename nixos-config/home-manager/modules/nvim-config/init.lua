vim.cmd([[
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
]])

-- The rest is from extraLuaConfig
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

-- 🔑 Сохранение
vim.keymap.set("n", "<leader>w", "<Cmd>w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>W", "<Cmd>wa<CR>", { desc = "Save all files" })

-- 🔑 Сохранить и закрыть буфер
vim.keymap.set("n", "<leader>q", "<Cmd>w<bar>Bdelete<CR>", { desc = "Save & close buffer" })
vim.keymap.set("n", "<leader>Q", "<Cmd>wa<bar>qa<CR>", { desc = "Save all & quit Neovim" })

-- 🔑 Быстро закрыть без сохранения
vim.keymap.set("n", "<leader>qq", "<Cmd>q!<CR>", { desc = "Force quit buffer" })


-- Neo-tree (без автозакрытия при открытии файла)
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

-- Alpha: Dashboard / Стартовая страница
pcall(function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- Заголовок - ASCII Art
    dashboard.section.header.val = {
        "███╗   ██╗ ██████╗ ██╗  ██╗ █████╗ ██╗   ██╗",
        "████╗  ██║██╔═══██╗██║  ██║██╔══██╗╚██╗ ██╔╝",
        "██╔██╗ ██║██║   ██║███████║███████║ ╚████╔╝ ",
        "██║╚██╗██║██║   ██║██╔══██║██╔══██║  ╚██╔╝  ",
        "██║ ╚████║╚██████╔╝██║  ██║██║  ██║   ██║   ",
        "╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ",
    }

    -- Кнопки
    dashboard.section.buttons.val = {
        dashboard.button("f", "󰈔  Find file",      ":Telescope find_files<CR>"),
        dashboard.button("g", "󰊄  Find word",      ":Telescope live_grep<CR>"),
        dashboard.button("r", "󰋚  Recent files",   ":Telescope oldfiles<CR>"),
        dashboard.button("b", "󰓩  Buffers",        ":Telescope buffers<CR>"),
        dashboard.button("n", "󰏫  New file",       ":enew<CR>"),
        dashboard.button("q", "󰅚  Quit",           ":qa<CR>"),
    }

    -- Футер
    dashboard.section.footer.val = require("alpha.fortune")()

    -- Применяем тему
    alpha.setup(dashboard.opts)
end)
