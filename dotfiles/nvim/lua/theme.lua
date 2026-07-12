local M = {}

local config_dir = vim.fn.expand("~/.config/theme")
local theme_file = config_dir .. "/current/nvim.lua"

function M.load()
    dofile(theme_file)
    vim.api.nvim_exec_autocmds("ColorScheme", { pattern = vim.g.colors_name })

    if package.loaded.lualine then
        require("lualine").setup({
            options = {
                icons_enabled = true,
                theme = vim.g.eucalyptus_lualine_theme,
            },
        })
    end
end

function M.setup()
    M.load()

    if M.watcher then
        return
    end

    M.watcher = vim.uv.new_fs_event()
    M.watcher:start(config_dir, {}, vim.schedule_wrap(M.load))
end

return M
