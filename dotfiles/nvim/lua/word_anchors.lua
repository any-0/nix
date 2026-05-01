local M = {}

local ns = vim.api.nvim_create_namespace("word_anchors")

M.enabled = true

local function get_motion_target(motion)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local saved_view = vim.fn.winsaveview()

    vim.cmd("silent! normal! " .. motion)

    local new_cursor = vim.api.nvim_win_get_cursor(0)
    vim.fn.winrestview(saved_view)

    if new_cursor[1] == cursor[1] and new_cursor[2] == cursor[2] then
        return nil
    end

    return { row = new_cursor[1] - 1, col = new_cursor[2] }
end

function M.update()
    if not M.enabled then return end

    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.cmd("redraw")

    -- Priority order
    local motions = {
        { key = ";", hl = "WordAnchorSemi" },
        { key = ",", hl = "WordAnchorComma" },
        { key = "w", hl = "WordAnchorw" },
        { key = "W", hl = "WordAnchorW" },
        { key = "e", hl = "WordAnchore" },
        { key = "E", hl = "WordAnchorE" },
        { key = "b", hl = "WordAnchorb" },
        { key = "B", hl = "WordAnchorB" },
    }

    local marked = {}
    for _, m in ipairs(motions) do
        local target = get_motion_target(m.key)
        if target then
            local key = target.row .. ":" .. target.col
            if not marked[key] then
                marked[key] = true
                pcall(vim.api.nvim_buf_set_extmark, buf, ns, target.row, target.col, {
                    hl_group = m.hl,
                    end_col = target.col + 1,
                    priority = 1000,
                    strict = false,
                })
            end
        end
    end
end

function M.toggle()
    M.enabled = not M.enabled
    if M.enabled then
        M.update()
    else
        local buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    end
end

function M.setup()
    vim.api.nvim_set_hl(0, "WordAnchorw", { underline = true, sp = "#3366FF" })
    vim.api.nvim_set_hl(0, "WordAnchore", { underline = true, sp = "#00CC00" })
    vim.api.nvim_set_hl(0, "WordAnchorb", { underline = true, sp = "#FF4422" })
    vim.api.nvim_set_hl(0, "WordAnchorW", { underline = true, sp = "#3366FF" })
    vim.api.nvim_set_hl(0, "WordAnchorE", { underline = true, sp = "#00CC00" })
    vim.api.nvim_set_hl(0, "WordAnchorB", { underline = true, sp = "#FF4422" })
    vim.api.nvim_set_hl(0, "WordAnchorSemi", { underline = true, bold = true, sp = "#FFBBBB", bg="#EEEEEE" })
    vim.api.nvim_set_hl(0, "WordAnchorComma", { underline = true, bold = true, sp = "#FFBBBB", bg="#EEEEEE" })

    local group = vim.api.nvim_create_augroup("WordAnchors", { clear = true })

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI" }, {
        group = group,
        callback = M.update,
    })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function()
            vim.schedule(M.update)
        end,
    })

    M.update()
end

return M
