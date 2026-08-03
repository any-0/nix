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

    secondary = "#@secondary@",
    accent = "#@accent@",
    success = "#@success@",
    warning = "#@warning@",

    selection = "#@selection@",
    line_bg = "#@surface@",
    comment = "#@muted@",
    ui_gray = "#@surfaceRaised@",

    error = "#@danger@",
    warn = "#@warning@",

    diff_add = "#@diffAdd@",
    diff_delete = "#@diffDelete@",
    diff_change = "#@diffChange@",
    diff_text = "#@diffChange@",
}

vim.g.eucalyptus_lualine_theme = {
    normal = {
        a = { fg = "#@foreground@", bg = c.ui_gray },
        b = { fg = "#@foreground@", bg = c.ui_gray },
        c = { fg = "#@onColor@", bg = c.secondary },
    },
    insert = {
        a = { fg = "#@foreground@", bg = c.ui_gray },
        b = { fg = "#@foreground@", bg = c.ui_gray },
        c = { fg = "#@onColor@", bg = c.success },
    },
    visual = {
        a = { fg = "#@foreground@", bg = c.ui_gray },
        b = { fg = "#@foreground@", bg = c.ui_gray },
        c = { fg = "#@onColor@", bg = c.accent },
    },
    replace = {
        a = { fg = "#@foreground@", bg = c.ui_gray },
        b = { fg = c.fg, bg = c.ui_gray },
        c = { fg = c.fg, bg = c.bg },
    },
    command = {
        a = { fg = "#@foreground@", bg = c.ui_gray },
        b = { fg = "#@foreground@", bg = c.ui_gray },
        c = { fg = c.fg, bg = c.bg },
    },
}

local highlights = {
    Normal = { fg = c.fg, bg = c.bg },
    NormalFloat = { fg = c.fg, bg = c.bg },
    FloatBorder = { fg = c.secondary, bg = c.bg },
    Cursor = { fg = "#@onColor@", bg = "#@secondary@", bold = true },
    CursorLine = { bg = c.line_bg },
    CursorLineNr = { fg = "#@foreground@", bold = true },
    LineNr = { fg = c.secondary, bold = true },
    SignColumn = { bg = c.bg },
    StatusLine = { fg = "#@onColor@", bg = c.accent, bold = true },
    StatusLineNC = { fg = c.fg, bg = "#@surfaceRaised@" },
    VertSplit = { fg = "#@muted@", bg = c.bg },
    Visual = { bg = c.selection, fg = "#@foreground@" },
    Pmenu = { fg = c.fg, bg = "#@surfaceRaised@" },
    PmenuSel = { fg = "#@onColor@", bg = c.accent },
    Search = { fg = c.fg, bg = c.selection },
    IncSearch = { fg = "#@onColor@", bg = c.accent },
    CurSearch = { fg = "#@onColor@", bg = c.accent },
    EasyMotionTarget = { fg = "#@onColor@", bg = c.secondary, bold = true },
    EasyMotionTarget2First = { fg = "#@onColor@", bg = c.accent, bold = true },
    EasyMotionTarget2Second = { fg = "#@onColor@", bg = c.success, bold = true },
    EasyMotionShade = { fg = c.comment },
    MatchParen = { fg = c.success, bold = true, underline = true },

    Comment = { fg = c.comment, italic = true },
    Constant = { fg = c.fg, bold = true },
    String = { fg = c.success },
    Character = { fg = c.success },
    Number = { fg = c.warning },
    Boolean = { fg = c.warning, bold = true },
    Float = { fg = c.warning },
    Identifier = { fg = c.fg },
    Function = { fg = c.accent, bold = true },
    Statement = { fg = c.secondary, bold = true },
    Conditional = { fg = c.secondary, bold = true },
    Repeat = { fg = c.secondary, bold = true },
    Label = { fg = c.secondary },
    Operator = { fg = c.secondary },
    Keyword = { fg = c.secondary, bold = true },
    PreProc = { fg = c.secondary },
    Include = { fg = c.secondary },
    Type = { fg = c.secondary, bold = true },
    Structure = { fg = c.secondary },
    Special = { fg = c.accent },
    Delimiter = { fg = "#@muted@" },
    Underlined = { underline = true },
    Error = { fg = c.error, bold = true },
    Todo = { fg = "#@onColor@", bg = c.secondary, bold = true },
    DiffAdd = { fg = c.fg, bg = c.diff_add },
    DiffDelete = { fg = c.error, bg = c.diff_delete },
    DiffChange = { fg = c.fg, bg = c.diff_change },
    DiffText = { fg = c.fg, bg = c.diff_text },
    diffAdded = { fg = c.success },
    diffRemoved = { fg = c.error },
    diffChanged = { fg = c.warn },
    diffFile = { fg = c.accent },
    diffNewFile = { fg = c.success },
    diffOldFile = { fg = c.error },
    diffLine = { fg = c.secondary },
    diffIndexLine = { fg = c.secondary },

    GitSignsAdd = { fg = c.success, bold = true },
    GitSignsChange = { fg = c.warn, bold = true },
    GitSignsDelete = { fg = c.error, bold = true },
    GitSignsTopdelete = { fg = c.error, bold = true },
    GitSignsChangedelete = { fg = c.warn, bold = true },

    ["@variable"] = { fg = c.fg },
    ["@variable.builtin"] = { fg = c.secondary, italic = true },
    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { fg = c.accent },
    ["@keyword"] = { link = "Keyword" },
    ["@string"] = { link = "String" },
    ["@type"] = { link = "Type" },
    ["@constructor"] = { fg = c.secondary },
    ["@property"] = { fg = c.accent },
    ["@field"] = { fg = c.fg },
    ["@parameter"] = { fg = "#@foreground@", italic = true },
    ["@punctuation.bracket"] = { fg = "#@muted@" },
    ["@punctuation.delimiter"] = { fg = "#@muted@" },
    ["@tag"] = { fg = c.secondary },
    ["@tag.delimiter"] = { fg = "#@muted@" },
    ["@tag.attribute"] = { fg = c.secondary },

    DiagnosticError = { fg = c.error },
    DiagnosticWarn = { fg = c.warn },
    DiagnosticInfo = { fg = c.accent },
    DiagnosticHint = { fg = c.secondary },
    DiagnosticUnderlineError = { underline = true, sp = c.error },
}

for group, settings in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, settings)
end

vim.opt.guicursor = "n-v-c:block-cursor,i-ci-ve:ver25-cursor,r-cr-o:hor20-cursor"
