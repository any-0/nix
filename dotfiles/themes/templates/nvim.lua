vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end

vim.o.background = "@variant@"
vim.o.termguicolors = true
vim.g.colors_name = "anyscheme"

local c = {
    bg = "#@background@",
    fg = "#@foreground@",

    teal_deep = "#@secondary@",
    cyan_ink = "#@accent@",
    emerald = "#@success@",
    aqua_dark = "#@tertiary@",
    olive_bold = "#@number@",

    selection = "#@selection@",
    line_bg = "#@surface@",
    comment = "#@muted@",
    ui_gray = "#@uiGray@",

    error = "#@danger@",
    warn = "#@warning@",

    diff_add = "#@diffAdd@",
    diff_delete = "#@diffDelete@",
    diff_change = "#@diffChange@",
    diff_text = "#@diffText@",
}

vim.g.eucalyptus_lualine_theme = {
    normal = {
        a = { fg = "#@onSurface@", bg = c.ui_gray },
        b = { fg = "#@onSurface@", bg = c.ui_gray },
        c = { fg = "#@bright@", bg = c.teal_deep },
    },
    insert = {
        a = { fg = "#@onSurface@", bg = c.ui_gray },
        b = { fg = "#@onSurface@", bg = c.ui_gray },
        c = { fg = "#@bright@", bg = c.emerald },
    },
    visual = {
        a = { fg = "#@onSurface@", bg = c.ui_gray },
        b = { fg = "#@onSurface@", bg = c.ui_gray },
        c = { fg = "#@bright@", bg = c.cyan_ink },
    },
    replace = {
        a = { fg = "#@onSurface@", bg = c.ui_gray },
        b = { fg = c.fg, bg = c.ui_gray },
        c = { fg = c.fg, bg = c.bg },
    },
    command = {
        a = { fg = "#@onSurface@", bg = c.ui_gray },
        b = { fg = "#@onSurface@", bg = c.ui_gray },
        c = { fg = c.fg, bg = c.bg },
    },
}

local highlights = {
    Normal = { fg = c.fg, bg = c.bg },
    NormalFloat = { fg = c.fg, bg = c.bg },
    FloatBorder = { fg = c.teal_deep, bg = c.bg },
    Cursor = { fg = "#@cursorForeground@", bg = "#@cursor@", bold = true },
    CursorLine = { bg = c.line_bg },
    CursorLineNr = { fg = "#@foreground@", bold = true },
    LineNr = { fg = c.teal_deep, bold = true },
    SignColumn = { bg = c.bg },
    StatusLine = { fg = "#@bright@", bg = c.cyan_ink, bold = true },
    StatusLineNC = { fg = c.fg, bg = "#@inactive@" },
    VertSplit = { fg = "#@muted@", bg = c.bg },
    Visual = { bg = c.selection, fg = "#@foreground@" },
    Pmenu = { fg = c.fg, bg = "#@popup@" },
    PmenuSel = { fg = "#@bright@", bg = c.cyan_ink },
    Search = { fg = "#@bright@", bg = c.aqua_dark },
    IncSearch = { fg = "#@bright@", bg = c.teal_deep },
    EasyMotionTarget = { fg = "#@bright@", bg = c.teal_deep, bold = true },
    EasyMotionTarget2First = { fg = "#@bright@", bg = c.cyan_ink, bold = true },
    EasyMotionTarget2Second = { fg = "#@bright@", bg = c.emerald, bold = true },
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
    Delimiter = { fg = "#@subtle@" },
    Underlined = { underline = true },
    Error = { fg = c.error, bold = true },
    Todo = { fg = "#@bright@", bg = c.teal_deep, bold = true },
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
    ["@parameter"] = { fg = "#@parameter@", italic = true },
    ["@punctuation.bracket"] = { fg = "#@subtle@" },
    ["@punctuation.delimiter"] = { fg = "#@subtle@" },
    ["@tag"] = { fg = c.teal_deep },
    ["@tag.delimiter"] = { fg = "#@tagDelimiter@" },
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
