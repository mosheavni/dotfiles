local autocmd = vim.api.nvim_create_autocmd

local M = {}

-- Shared Neovim default-theme palette (NvimDark*/NvimLight* colors resolved to
-- hex). Reused by the statusline:
--   local palette = require('user.colorscheme').palette
M.palette = {
  dark_grey2 = '#14161b', -- NvimDarkGrey2 (Normal background)
  dark_grey3 = '#2c2e33', -- NvimDarkGrey3
  dark_grey4 = '#4f5258', -- NvimDarkGrey4
  grey1 = '#eef1f8', -- NvimLightGrey1 (brightest fg)
  grey2 = '#e0e2ea', -- NvimLightGrey2 (Normal fg)
  grey4 = '#9b9ea4', -- NvimLightGrey4 (Comment)
  blue = '#a6dbff', -- NvimLightBlue
  cyan = '#8cf8f7', -- NvimLightCyan
  green = '#b3f6c0', -- NvimLightGreen
  magenta = '#ffcaff', -- NvimLightMagenta
  red = '#ffc0b9', -- NvimLightRed
  yellow = '#fce094', -- NvimLightYellow
}

function M.setup()
  local palette = M.palette

  -- Transparent background (requires a transparent terminal)
  local transparent_group = vim.api.nvim_create_augroup('TransparentBackground', { clear = true })
  autocmd('ColorScheme', {
    desc = 'Clear background of core highlight groups for terminal transparency',
    group = transparent_group,
    callback = function()
      for _, group in ipairs {
        'Normal',
        'NormalNC',
        'NormalFloat',
        'SignColumn',
        'EndOfBuffer',
        'MsgArea',
      } do
        vim.api.nvim_set_hl(0, group, { bg = 'none' })
      end
    end,
  })

  -- Re-add rose-pine's color richness on top of the intentionally near-monochrome
  -- default theme, drawing every color from the default theme's own NvimLight* palette.
  local theme_hl_group = vim.api.nvim_create_augroup('ThemeHighlights', { clear = true })
  autocmd('ColorScheme', {
    desc = 'Add syntax/plugin color on top of the minimal default theme palette',
    group = theme_hl_group,
    callback = function()
      local blue, cyan, green = palette.blue, palette.cyan, palette.green
      local magenta, red, yellow = palette.magenta, palette.red, palette.yellow
      local grey = palette.grey4
      local italic = true -- rose-pine-style slanted text (set false to disable)

      -- Keyword + syntax groups the default theme renders as plain grey.
      -- Parent groups cascade to their links (e.g. Constant -> Number/Boolean/@constant).
      local groups = {
        Keyword = { fg = magenta },
        ['@keyword.return'] = { fg = magenta },
        ['@keyword.repeat'] = { fg = magenta },
        ['@keyword.import'] = { fg = magenta },
        ['@keyword.exception'] = { fg = magenta },
        ['@keyword.conditional'] = { fg = magenta },
        ['@keyword.conditional.ternary'] = { fg = magenta },
        ['@keyword.storage'] = { fg = magenta },
        ['@keyword.directive'] = { fg = magenta },
        ['@keyword.directive.define'] = { fg = magenta },
        ['@keyword.operator'] = { fg = grey },
        ['@keyword.debug'] = { fg = red },
        Statement = { fg = magenta }, -- cascades to Conditional/Repeat/Exception/Keyword
        Label = { fg = cyan },
        Type = { fg = cyan }, -- cascades to Structure/StorageClass/Typedef/@type
        Constant = { fg = yellow }, -- cascades to Number/Boolean/Character/Float/@constant
        PreProc = { fg = magenta }, -- cascades to Define/Macro/PreCondit
        Include = { fg = blue }, -- imports (overrides PreProc cascade)
        Operator = { fg = grey }, -- cascades to @operator
        Delimiter = { fg = grey }, -- cascades to @punctuation/@punctuation.delimiter
        Title = { fg = cyan }, -- cascades to FloatTitle/FloatFooter
        FloatBorder = { fg = grey, bg = 'none' }, -- bg='none' preserves transparency
        WinSeparator = { fg = grey }, -- split divider (VertSplit links here)
        Underlined = { fg = magenta, underline = true },
        ['@variable.parameter'] = { fg = magenta, italic = italic },
        ['@variable.member'] = { fg = cyan, italic = italic },
        -- Color only method invocations. LSP semantic tokens use one group
        -- (@lsp.type.method) for calls and definitions and outrank treesitter, so
        -- clear it to defer to treesitter, which distinguishes call from definition.
        ['@function.method.call'] = { fg = blue },
        ['@lsp.type.method'] = {},
        ['@attribute'] = { fg = magenta },
        ['@string.regexp'] = { fg = magenta }, -- default links this to Special (cyan)
        FugitiveblameBoundary = { link = 'Keyword' },

        -- Fugitive status buffer
        fugitiveHeading = { fg = cyan, bold = true },
        fugitiveStagedHeading = { fg = cyan, bold = true },
        fugitiveUnstagedHeading = { fg = cyan, bold = true },
        fugitiveUntrackedHeading = { fg = cyan, bold = true },
        fugitiveSection = { fg = palette.grey2 },
        fugitiveStagedSection = { fg = palette.grey2 },
        fugitiveUnstagedSection = { fg = palette.grey2 },
        fugitiveUntrackedSection = { fg = red },
        fugitiveHash = { fg = yellow },
        fugitiveSymbolicRef = { fg = blue },
        fugitiveStop = { fg = blue },
        fugitiveCount = { fg = yellow },
        fugitiveModifier = { fg = cyan },
        fugitiveStagedModifier = { fg = yellow },
        fugitiveUnstagedModifier = { fg = yellow },
        fugitiveUntrackedModifier = { fg = red },
        fugitiveInstruction = { fg = cyan },
        fugitivePreposition = { fg = palette.grey2 },
        fugitiveDone = { fg = grey },
        fugitiveHunk = { fg = blue },
        fugitiveHeader = { fg = cyan },
        fugitiveHelpTag = { fg = cyan },
        fugitiveHelpHeader = { fg = cyan },

        -- rose-pine's signature slanted text: italic comments + variables.
        Comment = { fg = grey, italic = italic }, -- cascades to @comment
        ['@variable'] = { italic = italic }, -- keeps normal fg, adds slant
        ['@variable.builtin'] = { fg = red, italic = italic, bold = true }, -- self/this
        -- Markdown/comment emphasis renders with the matching font style.
        ['@markup.italic'] = { italic = italic },
        ['@markup.strong'] = { bold = true },
        ['@markup.strikethrough'] = { strikethrough = true },

        -- Gitsigns gutter: amber "changed" so it reads distinctly from green
        -- "added" (default theme makes both green/cyan, which are hard to tell apart).
        GitSignsAdd = { fg = green },
        GitSignsChange = { fg = yellow },
        GitSignsDelete = { fg = red },
      }
      for group, opts in pairs(groups) do
        vim.api.nvim_set_hl(0, group, opts)
      end

      -- Kind icons for blink.cmp (completion menu) and nvim-navic (winbar
      -- breadcrumbs); both render monochrome under the default theme.
      local kind_colors = {
        Text = grey,
        Method = cyan,
        Function = cyan,
        Constructor = cyan,
        Event = cyan,
        Field = blue,
        Variable = blue,
        Property = blue,
        EnumMember = blue,
        Key = blue,
        Keyword = magenta,
        Class = cyan,
        Interface = cyan,
        Struct = cyan,
        Enum = cyan,
        Module = cyan,
        Namespace = cyan,
        Package = cyan,
        Object = cyan,
        File = cyan,
        Folder = cyan,
        Constant = yellow,
        Value = yellow,
        Number = yellow,
        Boolean = yellow,
        Array = yellow,
        String = green,
        Snippet = magenta,
        Unit = magenta,
        TypeParameter = magenta,
        Color = red,
        Reference = red,
        Null = red,
        Operator = grey,
      }
      for kind, color in pairs(kind_colors) do
        vim.api.nvim_set_hl(0, 'BlinkCmpKind' .. kind, { fg = color })
        vim.api.nvim_set_hl(0, 'NavicIcons' .. kind, { fg = color })
      end
    end,
  })

  -- Terminal (:terminal, lazygit, etc.) palette. The default theme leaves these
  -- unset, so built-in terminals fall back to your terminal emulator's colors;
  -- map them to the default theme's own palette for a consistent look.
  local term = {
    [0] = palette.dark_grey4, -- black
    [8] = palette.grey4, -- bright black
    [1] = palette.red, -- red
    [9] = palette.red,
    [2] = palette.green, -- green
    [10] = palette.green,
    [3] = palette.yellow, -- yellow
    [11] = palette.yellow,
    [4] = palette.blue, -- blue
    [12] = palette.blue,
    [5] = palette.magenta, -- magenta
    [13] = palette.magenta,
    [6] = palette.cyan, -- cyan
    [14] = palette.cyan,
    [7] = palette.grey2, -- white
    [15] = palette.grey1, -- bright white
  }
  for i, color in pairs(term) do
    vim.g['terminal_color_' .. i] = color
  end

  -- Set the colorscheme last so the ColorScheme autocmds above fire on startup.
  vim.cmd.colorscheme 'default'
end

return M
