local M = {}

M.script_names = {
  "deploy-local.sh",
  "compile.sh",
  "build.sh",
  "run.sh",
}

function M.find_script()
  local cwd = vim.fn.getcwd()
  for _, name in ipairs(M.script_names) do
    local path = cwd .. "/" .. name
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
  return nil
end

function M.run_in_popup()
  local script = M.find_script()
  if not script then
    vim.notify("No matching script found", vim.log.levels.ERROR)
    return
  end
  local width  = math.floor(vim.o.columns * 0.4)
  local height = math.floor(vim.o.lines * 0.4)
  local row    = math.floor(vim.o.lines - height-4)
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
  vim.fn.termopen({ "bash", script })
  vim.cmd("startinsert")
  vim.keymap.set("t", "<Esc>", "<C-\\><C-n>:close<CR>", { buffer = buf })
end

function M.run_headless()
  local script = M.find_script()
  if not script then
    vim.notify("No matching script found", vim.log.levels.ERROR)
    return
  end

  vim.fn.jobstart({ "bash", script }, {
    detach = true,
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("Script finished successfully")
      else
        vim.notify("Script failed (exit " .. code .. ")", vim.log.levels.ERROR)
      end
    end,
  })
end

return M
