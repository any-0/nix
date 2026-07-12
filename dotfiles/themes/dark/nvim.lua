vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end

vim.o.background = "dark"
vim.o.termguicolors = true
vim.g.colors_name = "anyscheme"

local c = {
    bg = "#202026",
    fg = "#F2F2F4",

    teal_deep = "#5BC8AF",
    cyan_ink = "#7AA2F7",
    emerald = "#8BD49C",
    aqua_dark = "#6FD6C5",
    olive_bold = "#B8CC7A",

    selection = "#34495E",
    line_bg = "#292932",
    comment = "#8B8B95",
    ui_gray = "#555563",

    error = "#FF7A90",
    warn = "#E0AF68",

    diff_add = "#244333",
    diff_delete = "#4A2932",
    diff_change = "#4A4029",
    diff_text = "#63532D",
}

vim.g.eucalyptus_lualine_theme = {
    normal = {
        a = { fg = "#FFFFFF", bg = c.ui_gray },
        b = { fg = "#FFFFFF", bg = c.ui_gray },
        c = { fg = "#FFFFFF", bg = c.teal_deep },
    },
    insert = {
        a = { fg = "#FFFFFF", bg = c.ui_gray },
        b = { fg = "#FFFFFF", bg = c.ui_gray },
        c = { fg = "#FFFFFF", bg = c.emerald },
    },
    visual = {
        a = { fg = "#FFFFFF", bg = c.ui_gray },
        b = { fg = "#FFFFFF", bg = c.ui_gray },
        c = { fg = "#FFFFFF", bg = c.cyan_ink },
    },
    replace = {
        a = { fg = "#FFFFFF", bg = c.ui_gray },
        b = { fg = c.fg, bg = c.ui_gray },
        c = { fg = c.fg, bg = c.bg },
    },
    command = {
        a = { fg = "#FFFFFF", bg = c.ui_gray },
        b = { fg = "#FFFFFF", bg = c.ui_gray },
        c = { fg = c.fg, bg = c.bg },
    },
}

local highlights = {
    Normal = { fg = c.fg, bg = c.bg },
    NormalFloat = { fg = c.fg, bg = c.bg },
    FloatBorder = { fg = c.teal_deep, bg = c.bg },
    Cursor = { fg = c.bg, bg = c.teal_deep, bold = true },
    CursorLine = { bg = c.line_bg },
    CursorLineNr = { fg = "#F2F2F4", bold = true },
    LineNr = { fg = c.teal_deep, bold = true },
    SignColumn = { bg = c.bg },
    StatusLine = { fg = "#FFFFFF", bg = c.cyan_ink, bold = true },
    StatusLineNC = { fg = c.fg, bg = "#454550" },
    VertSplit = { fg = "#8B8B95", bg = c.bg },
    Visual = { bg = c.selection, fg = "#F2F2F4" },
    Pmenu = { fg = c.fg, bg = "#303039" },
    PmenuSel = { fg = "#FFFFFF", bg = c.cyan_ink },
    Search = { fg = "#FFFFFF", bg = c.aqua_dark },
    IncSearch = { fg = "#FFFFFF", bg = c.teal_deep },
    EasyMotionTarget = { fg = "#FFFFFF", bg = c.teal_deep, bold = true },
    EasyMotionTarget2First = { fg = "#FFFFFF", bg = c.cyan_ink, bold = true },
    EasyMotionTarget2Second = { fg = "#FFFFFF", bg = c.emerald, bold = true },
    EasyMotionShade = { fg = c.comment },
    MatchParen = { fg = c.emerald, bold = true, underline = true },

    Comment = { fg = c.comment, italic = true },
    Constant = { fg = c.fg, bold = true },
    String = { fg = c.emerald },
    Character = { fg = c.emerald },
    Number = { fg = c.olive_bold },
    Boolean = { fg = c.olive_bold, bold = true },
    Float = { fg = c.olive_bold },
    Identifier = { fg = c.fg },
    Function = { fg = c.cyan_ink, bold = true },
    Statement = { fg = c.teal_deep, bold = true },
    Conditional = { fg = c.teal_deep, bold = true },
    Repeat = { fg = c.teal_deep, bold = true },
    Label = { fg = c.teal_deep },
    Operator = { fg = c.teal_deep },
    Keyword = { fg = c.teal_deep, bold = true },
    PreProc = { fg = c.aqua_dark },
    Include = { fg = c.teal_deep },
    Type = { fg = c.aqua_dark, bold = true },
    Structure = { fg = c.aqua_dark },
    Special = { fg = c.cyan_ink },
    Delimiter = { fg = "#D8D8DC" },
    Underlined = { underline = true },
    Error = { fg = c.error, bold = true },
    Todo = { fg = "#FFFFFF", bg = c.teal_deep, bold = true },
    DiffAdd = { fg = c.fg, bg = c.diff_add },
    DiffDelete = { fg = c.error, bg = c.diff_delete },
    DiffChange = { fg = c.fg, bg = c.diff_change },
    DiffText = { fg = c.fg, bg = c.diff_text },
    diffAdded = { fg = c.emerald },
    diffRemoved = { fg = c.error },
    diffChanged = { fg = c.warn },
    diffFile = { fg = c.cyan_ink },
    diffNewFile = { fg = c.emerald },
    diffOldFile = { fg = c.error },
    diffLine = { fg = c.teal_deep },
    diffIndexLine = { fg = c.aqua_dark },

    GitSignsAdd = { fg = c.emerald, bold = true },
    GitSignsChange = { fg = c.warn, bold = true },
    GitSignsDelete = { fg = c.error, bold = true },
    GitSignsTopdelete = { fg = c.error, bold = true },
    GitSignsChangedelete = { fg = c.warn, bold = true },

    ["@variable"] = { fg = c.fg },
    ["@variable.builtin"] = { fg = c.teal_deep, italic = true },
    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { fg = c.cyan_ink },
    ["@keyword"] = { link = "Keyword" },
    ["@string"] = { link = "String" },
    ["@type"] = { link = "Type" },
    ["@constructor"] = { fg = c.aqua_dark },
    ["@property"] = { fg = c.cyan_ink },
    ["@field"] = { fg = c.fg },
    ["@parameter"] = { fg = "#D8D8DC", italic = true },
    ["@punctuation.bracket"] = { fg = "#D8D8DC" },
    ["@punctuation.delimiter"] = { fg = "#D8D8DC" },
    ["@tag"] = { fg = c.teal_deep },
    ["@tag.delimiter"] = { fg = "#A8A8B0" },
    ["@tag.attribute"] = { fg = c.aqua_dark },

    DiagnosticError = { fg = c.error },
    DiagnosticWarn = { fg = c.warn },
    DiagnosticInfo = { fg = c.cyan_ink },
    DiagnosticHint = { fg = c.teal_deep },
    DiagnosticUnderlineError = { underline = true, sp = c.error },
}

for group, settings in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, settings)
end

vim.opt.guicursor = "n-v-c:block-cursor,i-ci-ve:ver25-cursor,r-cr-o:hor20-cursor"
