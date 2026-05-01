local M = {}

function M.setup()
    local python_format_group = vim.api.nvim_create_augroup("PythonRuffFormatOnSave", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function(ev)
            vim.api.nvim_clear_autocmds({ group = python_format_group, buffer = ev.buf })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = python_format_group,
                buffer = ev.buf,
                callback = function()
                    if vim.fn.executable("ruff") ~= 1 then
                        return
                    end

                    local filename = vim.api.nvim_buf_get_name(ev.buf)
                    if filename == "" then
                        return
                    end

                    local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
                    local input = table.concat(lines, "\n")
                    if vim.bo[ev.buf].endofline then
                        input = input .. "\n"
                    end

                    local output = vim.fn.system({ "ruff", "format", "--stdin-filename", filename, "-" }, input)
                    if vim.v.shell_error ~= 0 then
                        return
                    end

                    local formatted = vim.split(output, "\n", { plain = true })
                    if #formatted > 0 and formatted[#formatted] == "" then
                        table.remove(formatted, #formatted)
                    end

                    vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, formatted)
                end,
            })
        end,
    })
end

return M
