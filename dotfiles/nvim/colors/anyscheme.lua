vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end

vim.o.background = "light"
vim.o.termguicolors = true
vim.g.colors_name = "anyscheme"

local c = {
    bg          = "#fcf9f0",
    fg          = "#000000",

    teal_deep   = "#009393",
    cyan_ink    = "#0074b1",
    emerald     = "#008800",
    aqua_dark   = "#008080",
    olive_bold  = "#2A6500",

    selection   = "#C4FFFF",
    line_bg     = "#E8E8E8",
    comment     = "#888888",
    ui_gray     = "#B0B0B0",

    error       = "#8B0000",
    warn        = "#664400",

    diff_add    = "#9BE7A7",
    diff_delete = "#F2A6A6",
    diff_change = "#F2DEA0",
    diff_text   = "#E0C46C",
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
    Normal       = { fg = c.fg, bg = c.bg },
    NormalFloat  = { fg = c.fg, bg = c.bg }, 
    FloatBorder  = { fg = c.teal_deep, bg = c.bg },
    Cursor       = { fg = "#000000", bg = "#77AA77", bold = true },
    CursorLine   = { bg = c.line_bg },
    CursorLineNr = { fg = "#000000", bold = true },
    LineNr       = { fg = c.teal_deep, bold = true },
    SignColumn   = { bg = c.bg },
    StatusLine   = { fg = "#FFFFFF", bg = c.cyan_ink, bold = true },
    StatusLineNC = { fg = c.fg, bg = "#A0A0A0" },
    VertSplit    = { fg = "#888888", bg = c.bg },
    Visual       = { bg = c.selection, fg = "#000000" },
    Pmenu        = { fg = c.fg, bg = "#CCCCCC" },
    PmenuSel     = { fg = "#FFFFFF", bg = c.cyan_ink },
    Search       = { fg = "#FFFFFF", bg = c.aqua_dark },
    IncSearch    = { fg = "#FFFFFF", bg = c.teal_deep },
    EasyMotionTarget        = { fg = "#FFFFFF", bg = c.teal_deep, bold = true },
    EasyMotionTarget2First  = { fg = "#FFFFFF", bg = c.cyan_ink, bold = true },
    EasyMotionTarget2Second = { fg = "#FFFFFF", bg = c.emerald, bold = true },
    EasyMotionShade         = { fg = c.comment },
    MatchParen   = { fg = c.emerald, bold = true, underline = true },

    Comment      = { fg = c.comment, italic = true },
    Constant     = { fg = c.fg, bold = true },
    String       = { fg = c.emerald },
    Character    = { fg = c.emerald },
    Number       = { fg = c.olive_bold },
    Boolean      = { fg = c.olive_bold, bold = true },
    Float        = { fg = c.olive_bold },
    Identifier   = { fg = c.fg },
    Function     = { fg = c.cyan_ink, bold = true },
    Statement    = { fg = c.teal_deep, bold = true },
    Conditional  = { fg = c.teal_deep, bold = true },
    Repeat       = { fg = c.teal_deep, bold = true },
    Label        = { fg = c.teal_deep },
    Operator     = { fg = c.teal_deep },
    Keyword      = { fg = c.teal_deep, bold = true },
    PreProc      = { fg = c.aqua_dark },
    Include      = { fg = c.teal_deep },
    Type         = { fg = c.aqua_dark, bold = true },
    Structure    = { fg = c.aqua_dark },
    Special      = { fg = c.cyan_ink },
    Delimiter    = { fg = "#222222" },
    Underlined   = { underline = true },
    Error        = { fg = c.error, bold = true },
    Todo         = { fg = "#FFFFFF", bg = c.teal_deep, bold = true },
    DiffAdd      = { fg = c.fg, bg = c.diff_add },
    DiffDelete   = { fg = c.error, bg = c.diff_delete },
    DiffChange   = { fg = c.fg, bg = c.diff_change },
    DiffText     = { fg = c.fg, bg = c.diff_text },
    diffAdded    = { fg = c.emerald },
    diffRemoved  = { fg = c.error },
    diffChanged  = { fg = c.warn },
    diffFile     = { fg = c.cyan_ink },
    diffNewFile  = { fg = c.emerald },
    diffOldFile  = { fg = c.error },
    diffLine     = { fg = c.teal_deep },
    diffIndexLine = { fg = c.aqua_dark },

    GitSignsAdd          = { fg = c.emerald, bold = true },
    GitSignsChange       = { fg = c.warn, bold = true },
    GitSignsDelete       = { fg = c.error, bold = true },
    GitSignsTopdelete    = { fg = c.error, bold = true },
    GitSignsChangedelete = { fg = c.warn, bold = true },

    ["@variable"]          = { fg = c.fg },
    ["@variable.builtin"]  = { fg = c.teal_deep, italic = true },
    ["@function"]          = { link = "Function" },
    ["@function.builtin"]  = { fg = c.cyan_ink },
    ["@keyword"]           = { link = "Keyword" },
    ["@string"]            = { link = "String" },
    ["@type"]              = { link = "Type" },
    ["@constructor"]       = { fg = c.aqua_dark },
    ["@property"]          = { fg = c.cyan_ink }, 
    ["@field"]             = { fg = c.fg },
    ["@parameter"]         = { fg = "#202020", italic = true },
    ["@punctuation.bracket"] = { fg = "#222222" },
    ["@punctuation.delimiter"] = { fg = "#222222" },
    ["@tag"]               = { fg = c.teal_deep },
    ["@tag.delimiter"]     = { fg = "#444444" },
    ["@tag.attribute"]     = { fg = c.aqua_dark },

    DiagnosticError    = { fg = c.error },
    DiagnosticWarn     = { fg = c.warn },
    DiagnosticInfo     = { fg = c.cyan_ink },
    DiagnosticHint     = { fg = c.teal_deep },
    DiagnosticUnderlineError = { underline = true, sp = c.error },
}

for group, settings in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, settings)
end

vim.opt.guicursor = "n-v-c:block-cursor,i-ci-ve:ver25-cursor,r-cr-o:hor20-cursor"
