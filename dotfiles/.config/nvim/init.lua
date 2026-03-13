-- Leader (must be before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

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
vim.opt.sidescrolloff = 8
vim.opt.scrolloff = 10
vim.opt.statuscolumn = " %l  │  "
vim.cmd.colorscheme("anyscheme")
vim.opt.pumheight = 5
vim.opt.pumwidth = 30
vim.opt.iskeyword:remove("_")

vim.cmd([[
  cabbrev Wq wq
  cabbrev W  w
  cabbrev Q  q
]])

-- Persistent undo

vim.opt.undofile   = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 1000
local undo_root = vim.fn.stdpath('state') .. '/undo'
vim.opt.undodir = undo_root .. '//'

-- Keymaps

vim.keymap.set({ "n", "v", "o", "i" }, "<F1>", "<Nop>")
vim.keymap.set({ "n", "v", "o" }, "§", "^")
vim.keymap.set({ "n", "v", "o" }, "<S-§>", "^")
vim.keymap.set("n", "<C-d>", "m'<C-d>zz")
vim.keymap.set("n", "<C-u>", "m'<C-u>zz")
vim.keymap.set({ "v", "o" }, "<C-d>", "<C-d>zz")
vim.keymap.set({ "v", "o" }, "<C-u>", "<C-u>zz")
vim.keymap.set({ "n", "v", "o" }, ";", ",")
vim.keymap.set({ "n", "v", "o" }, ",", ";")
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
vim.keymap.set("n", "<Tab>", "<C-i>")
vim.keymap.set("i", "<C-Space>", "<C-x><C-n>")
vim.keymap.set("n", "<Home>", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end)


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
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    icons_enabled = true,
                    theme = vim.g.eucalyptus_lualine_theme
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            vim.diagnostic.config({
                virtual_text = false,
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = true,
                float = { border = "rounded", source = true },
            })

            -- Force undercurls for diagnostics
            vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "Red" })
            vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = "Orange" })
            vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = "LightBlue" })
            vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = "LightGrey" })

            vim.lsp.config("pyright", {
                cmd = { "pyright-langserver", "--stdio" },
                settings = {
                    python = {
                        analysis = {
                            typeCheckingMode = "basic",
                            diagnosticSeverityOverrides = {
                                reportMissingImports = "warning",
                                reportMissingModuleSource = "none",
                                reportOptionalMemberAccess = "none",
                                reportArgumentType = "warning",
                                reportAttributeAccessIssue = "warning",
                            },
                        },
                    },
                },
            })

            vim.lsp.config("clangd", {
                cmd = { "clangd" },
            })
            vim.lsp.config("ts_ls", {
                cmd = { "typescript-language-server", "--stdio" },
            })
            vim.lsp.config("rust_analyzer", {
                cmd = { "rust-analyzer" },
            })
            vim.lsp.config("dockerls", {
                cmd = { "docker-langserver", "--stdio" },
            })
            vim.lsp.config("docker_compose_language_service", {
                cmd = { "docker-compose-langserver", "--stdio" },
            })
            vim.lsp.config("bashls", {
                cmd = { "bash-language-server", "start" },
            })

            vim.lsp.enable("pyright")
            vim.lsp.enable("clangd")
            vim.lsp.enable("ts_ls")
            vim.lsp.enable("rust_analyzer")
            vim.lsp.enable("dockerls")
            vim.lsp.enable("docker_compose_language_service")
            vim.lsp.enable("bashls")

            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(ev)
                    local opts = { buffer = ev.buf }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
                    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
                    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                    vim.keymap.set("n", "gs", "<cmd>LspClangdSwitchSourceHeader<CR>", opts)
                end,
            })
        end,
    },

    -- Completion
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                window = {
                    completion = {
                        side_padding = 0,
                    },
                },
                formatting = {
                    format = function(_, item)
                        local max = 28
                        if vim.fn.strchars(item.abbr) > max then
                            item.abbr = vim.fn.strcharpart(item.abbr, 0, max) .. "..."
                        end
                        return item
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm({ select = false }),
                    ["<Tab>"] = cmp.mapping.select_next_item(),
                    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                }),
                sources = {
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                },
            })
        end,
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup()
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            local cmp = require("cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
    },
}, { lockfile = vim.fn.stdpath("data") .. "/lazy/lazy-lock.json", })

local ts_languages = {
    "python", "cpp", "lua", "bash", "json",
    "yaml", "javascript", "typescript", "tsx",
    "html", "css", "latex", "rust"
}

vim.api.nvim_create_autocmd("FileType", {
    pattern = ts_languages,
    callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

require("python_ruff_format").setup()

vim.keymap.set('n', '<End>', function()
  local cmd = os.getenv("RUN_CMD")
  if not cmd then
    vim.notify("RUN_CMD not set", vim.log.levels.WARN)
    return
  end

  local dir = os.getenv("DIRENV_DIR")
  if dir then
    dir = dir:gsub("^-", "")
  else
    dir = vim.fn.getcwd()
  end

  local width  = math.floor(vim.o.columns * 0.4)
  local height = math.floor(vim.o.lines * 0.4)
  local row    = math.floor(vim.o.lines - height - 4)
  local col    = math.floor(vim.o.columns - width)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    border = "rounded",
    style = "minimal",
  })
  vim.fn.termopen({ "bash", "-c", "cd " .. vim.fn.shellescape(dir) .. " && " .. cmd })
  vim.cmd("startinsert")
  vim.keymap.set("t", "<Esc>", "<C-\\><C-n>:close<CR>", { buffer = buf })
end, { desc = "Run RUN_CMD in popup" })

require("word_anchors").setup()

-- Rename tmux window to current file
if os.getenv("TMUX") then
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
            local name = vim.fn.expand("%:t")
            if name == "" then name = "[nvim]" end
            vim.fn.system("tmux rename-window " .. vim.fn.shellescape(name))
        end,
    })
    vim.api.nvim_create_autocmd("VimLeave", {
        callback = function()
            vim.fn.system("tmux set-window-option automatic-rename on")
        end,
    })
end
