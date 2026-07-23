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
vim.opt.fillchars:append({ eob = " " })
vim.opt.swapfile = false
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.list = true
vim.opt.listchars = { trail = "·" }
vim.opt.sidescrolloff = 8
vim.opt.scrolloff = 10
vim.opt.statuscolumn = " %s %=%l  │  "
vim.opt.signcolumn = "yes"
vim.cmd.colorscheme("anyscheme")
vim.opt.pumheight = 8
vim.opt.pumwidth = 30
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.iskeyword:remove("_")

vim.cmd([[
  cabbrev Wq wq
  cabbrev W  w
  cabbrev Q  q
]])

-- Persistent undo

vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 1000
local undo_root = vim.fn.stdpath("state") .. "/undo"
vim.opt.undodir = undo_root .. "//"

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
vim.keymap.set("n", "<Home>", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end)

-- Plugins

vim.g.EasyMotion_keys = "asdghklqwertzuiopxycvbnmfj"
vim.keymap.set({ "n", "x", "o" }, "<Space>", "<Plug>(easymotion-s)", { remap = true })

require("lualine").setup({
    options = {
        icons_enabled = true,
        theme = vim.g.eucalyptus_lualine_theme,
    },
})

require("gitsigns").setup({
    signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "-" },
        topdelete = { text = "-" },
        changedelete = { text = "±" },
    },
    on_attach = function(bufnr)
        local gs = require("gitsigns")
        local opts = { buffer = bufnr }

        vim.keymap.set("n", "]h", gs.next_hunk, opts)
        vim.keymap.set("n", "[h", gs.prev_hunk, opts)
        vim.keymap.set("n", "<leader>hp", gs.preview_hunk, opts)
        vim.keymap.set("n", "<leader>hr", gs.reset_hunk, opts)
        vim.keymap.set("n", "<leader>hb", gs.blame_line, opts)
    end,
})

local easymotion_gitsigns = vim.api.nvim_create_augroup("EasyMotionGitsigns", { clear = true })
vim.api.nvim_create_autocmd("User", {
    group = easymotion_gitsigns,
    pattern = "EasyMotionPromptBegin",
    callback = function()
        require("gitsigns").detach()
    end,
})
vim.api.nvim_create_autocmd("User", {
    group = easymotion_gitsigns,
    pattern = "EasyMotionPromptEnd",
    callback = function()
        require("gitsigns").attach()
    end,
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded", source = true },
})

vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "Red" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = "Orange" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = "LightBlue" })
vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = "LightGrey" })

vim.lsp.config("pyright", {
    cmd = { "pyright-langserver", "--stdio" },
    capabilities = capabilities,
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
    capabilities = capabilities,
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
})
vim.lsp.config("arduino_language_server", {
    cmd = {
        "arduino-language-server",
        "-cli",
        "arduino-cli",
        "-cli-config",
        os.getenv("ARDUINO_CLI_CONFIG") or (vim.fn.getcwd() .. "/arduino-cli.yaml"),
        "-clangd",
        "clangd",
        "-fqbn",
        os.getenv("ARDUINO_FQBN") or "arduino:avr:uno",
    },
    capabilities = capabilities,
})
vim.lsp.config("ts_ls", {
    cmd = { "typescript-language-server", "--stdio" },
    capabilities = capabilities,
})
vim.lsp.config("rust_analyzer", {
    cmd = { "rust-analyzer" },
    capabilities = capabilities,
})
vim.lsp.config("dockerls", {
    cmd = { "docker-langserver", "--stdio" },
    capabilities = capabilities,
})
vim.lsp.config("docker_compose_language_service", {
    cmd = { "docker-compose-langserver", "--stdio" },
    capabilities = capabilities,
})
vim.lsp.config("bashls", {
    cmd = { "bash-language-server", "start" },
    capabilities = capabilities,
})
vim.lsp.config("texlab", {
    cmd = { "texlab" },
    capabilities = capabilities,
})
vim.lsp.config("nil_ls", {
    cmd = { "nil" },
    capabilities = capabilities,
})
vim.lsp.config("lua_ls", {
    cmd = { "lua-language-server" },
    capabilities = capabilities,
    settings = {
        Lua = {
            diagnostics = {
                globals = { "vim" },
            },
        },
    },
})

vim.lsp.enable({
    "pyright",
    "clangd",
    "arduino_language_server",
    "ts_ls",
    "rust_analyzer",
    "dockerls",
    "docker_compose_language_service",
    "bashls",
    "texlab",
    "nil_ls",
    "lua_ls",
})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local opts = { buffer = ev.buf }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client.name == "clangd" then
            vim.keymap.set("n", "gs", "<cmd>LspClangdSwitchSourceHeader<CR>", opts)
        end
    end,
})

local cmp = require("cmp")
cmp.setup({
    window = {
        completion = {
            side_padding = 0,
            scrollbar = false,
        },
        documentation = {
            max_width = 50,
            max_height = 12,
        },
    },
    formatting = {
        fields = { "abbr" },
        format = function(_, item)
            local max = 28
            if vim.fn.strchars(item.abbr) > max then
                item.abbr = vim.fn.strcharpart(item.abbr, 0, max - 1) .. "…"
            end
            return item
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end, { "i", "s" }),
    }),
    sources = {
        { name = "nvim_lsp" },
        { name = "buffer" },
        { name = "path" },
    },
})

require("nvim-autopairs").setup()
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

local ts_languages = {
    "arduino",
    "bash",
    "c",
    "cpp",
    "css",
    "diff",
    "dockerfile",
    "gitignore",
    "html",
    "javascript",
    "json",
    "kdl",
    "kitty",
    "latex",
    "lua",
    "make",
    "markdown",
    "nix",
    "python",
    "rust",
    "tmux",
    "toml",
    "typescript",
    "tsx",
    "yaml",
}

vim.api.nvim_create_autocmd("FileType", {
    pattern = ts_languages,
    callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

require("python_ruff_format").setup()

vim.keymap.set("n", "<End>", function()
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

    local width = math.floor(vim.o.columns * 0.4)
    local height = math.floor(vim.o.lines * 0.4)
    local row = math.floor(vim.o.lines - height - 4)
    local col = math.floor(vim.o.columns - width)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
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

-- Rename tmux window to current file
if os.getenv("TMUX") then
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
            local name = vim.fn.expand("%:t")
            if name == "" then
                name = "[nvim]"
            end
            vim.fn.system("tmux rename-window " .. vim.fn.shellescape(name))
        end,
    })
    vim.api.nvim_create_autocmd("VimLeave", {
        callback = function()
            vim.fn.system("tmux set-window-option automatic-rename on")
        end,
    })
end
