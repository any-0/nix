-- Opts

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.termguicolors = true
vim.opt.fillchars:append { eob = " " }
vim.opt.swapfile = false
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.list = true
vim.opt.listchars = { trail = "·" }
vim.opt.scrolloff = 16
vim.opt.sidescrolloff = 8
-- vim.opt.cursorline = true
vim.opt.statuscolumn = " %l  │  "
vim.cmd.colorscheme("anyscheme")


-- Persistent undo

vim.opt.undofile   = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 1000
local undo_root = vim.fn.stdpath('state') .. '/undo'
vim.opt.undodir = undo_root .. '//'


-- Files are opened at the last visited line

vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local last_pos = vim.fn.line([['"]])
        if last_pos > 1 and last_pos <= vim.fn.line("$") then
            vim.schedule(function()
                vim.cmd('normal! g`"zz')
            end)
        end
    end,
})


-- Upper case :wq, :w, and :q alias

vim.cmd([[
  cabbrev Wq wq
  cabbrev W  w
  cabbrev Q  q
]])


-- Keymaps

vim.keymap.set({ "n", "v", "o", "i" }, "<F1>", "<Nop>")
vim.keymap.set({ "n", "v", "o" }, "§", "^")
vim.keymap.set({ "n", "v", "o" }, "<C-d>", "<C-d>zz")
vim.keymap.set({ "n", "v", "o" }, "<C-u>", "<C-u>zz")
vim.keymap.set({ "n", "v", "o" }, ";", ",")
vim.keymap.set({ "n", "v", "o" }, ",", ";")
vim.keymap.set({ "n", "v", "o" }, "-", "/")
vim.keymap.set({ "n", "v", "o" }, "_", "?")
vim.keymap.set({ "n", "v", "o" }, "<C-l>", "<C-i>")
vim.keymap.set({ "n", "v", "o" }, "<C-Left>", "b")
vim.keymap.set({ "n", "v", "o" }, "<C-Right>", "e")
vim.keymap.set({ "n", "v", "o" }, "<C-Up>", "3k")
vim.keymap.set({ "n", "v", "o" }, "<C-Down>", "3j")
vim.keymap.set({ "n", "v", "o" }, "<S-Up>", "10k")
vim.keymap.set({ "n", "v", "o" }, "<S-Down>", "10j")
vim.keymap.set({ "n", "v" }, "x", '"_x')
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "U", "<C-r>")
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("n", "<Tab>", ":set wrap!<CR>")
vim.keymap.set("i", "<C-Space>", "<C-x><C-n>")


-- Lazy

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)


-- Lazy plugins

require("lazy").setup({
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
        },
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "python", "cpp", "lua", "bash", "json",
                    "yaml", "javascript", "typescript", "tsx",
                    "html", "css", "latex", "rust"
                },
                highlight = { enable = true },
                indent = { enable = true },
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ["if"] = "@function.inner",
                            ["af"] = "@function.outer",
                            ["a#"] = "@comment.outer",
                            ["i#"] = "@comment.inner",
                            ["ac"] = "@call.outer",
                            ["ic"] = "@call.inner",
                            ["al"] = "@loop.outer",
                            ["il"] = "@loop.inner",
                            ["aa"] = "@parameter.outer",
                            ["ia"] = "@parameter.inner",
                            ["ai"] = "@conditional.outer",
                            ["ii"] = "@conditional.inner",
                            ["ae"] = "@assignment.outer",
                            ["ie"] = "@assignment.inner",
                            ["le"] = "@assignment.lhs",
                            ["re"] = "@assignment.rhs",
                            ["in"] = "@number.inner",
                        }
                    },
                    move = {
                        enable = true,
                        set_jumps = true,
                        goto_next_start = {
                            ["mf"] = "@function.outer",
                            ["mc"] = "@call.outer",
                            ["m#"] = "@comment.outer",
                            ["ml"] = "@loop.outer",
                            ["ma"] = "@parameter.inner",
                            ["mi"] = "@conditional.outer",
                            ["me"] = "@assignment.outer",
                            ["mn"] = "@number.inner",
                            ["mv"] = "@variable.inner",
                        },
                        goto_previous_start = {
                            ["Mf"] = "@function.outer",
                            ["Mc"] = "@call.outer",
                            ["M#"] = "@comment.outer",
                            ["Ml"] = "@loop.outer",
                            ["Ma"] = "@parameter.inner",
                            ["Mi"] = "@conditional.outer",
                            ["Me"] = "@assignment.outer",
                            ["Mn"] = "@number.inner",
                        },
                    }
                }
            })
        end
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    icons_enabled = true,
                    theme = vim.g.eucalyptus_lualine_theme 
                },
                sections = {
                    lualine_c = {
                        {
                            "filename",
                            path = 2,
                        },
                    },
                },
            })
        end,
    },
    {
        "sphamba/smear-cursor.nvim",
        opts = {
           cursor_color = "#009393",
            stiffness = 0.5,
            trailing_stiffness = 0.3,
            smear_between_buffers = true,
            smear_between_neighbor_lines = true,
            scroll_buffer_space = true,
            legacy_computing_symbols_support = false,
               never_draw_over_target = true,
        },
    }
}, { lockfile = vim.fn.stdpath("data") .. "/lazy/lazy-lock.json", })





local runner = require("run_script")

vim.keymap.set("n", "ß", runner.run_in_popup, {
  desc = "Run project script in popup terminal",
})

vim.keymap.set("n", "?", runner.run_headless, {
  desc = "Run project script headless",
})

require("word_anchors").setup()
