local M = {}
local cache = {} -- [bufnr] = { symbols, location }

-- stylua: ignore
local kind_icons = {
  [1]   = '󰈙 ', -- File
  [2] = ' ', -- Module
  [3]   = '󰌗 ', -- Namespace
  [4] = ' ', -- Package
  [5]   = '󰌗 ', -- Class
  [6]   = '󰆧 ', -- Method
  [7] = ' ', -- Property
  [8] = ' ', -- Field
  [9] = ' ', -- Constructor
  [10]  = '󰕘 ', -- Enum
  [11]  = '󰕘 ', -- Interface
  [12]  = '󰊕 ', -- Function
  [13]  = '󰆧 ', -- Variable
  [14]  = '󰏿 ', -- Constant
  [15]  = '󰀬 ', -- String
  [16]  = '󰎠 ', -- Number
  [17]  = '◩ ',  -- Boolean
  [18]  = '󰅪 ', -- Array
  [19]  = '󰅩 ', -- Object
  [20]  = '󰌋 ', -- Key
  [21]  = '󰟢 ', -- Null
  [22] = ' ', -- EnumMember
  [23]  = '󰌗 ', -- Struct
  [24] = ' ', -- Event
  [25]  = '󰆕 ', -- Operator
  [26]  = '󰊄 ', -- TypeParameter
  [255] = '󰉨 ', -- Macro
}

-- stylua: ignore
local kind_names = {
  [1]   = 'File',          [2]   = 'Module',        [3]   = 'Namespace',
  [4]   = 'Package',       [5]   = 'Class',          [6]   = 'Method',
  [7]   = 'Property',      [8]   = 'Field',          [9]   = 'Constructor',
  [10]  = 'Enum',          [11]  = 'Interface',      [12]  = 'Function',
  [13]  = 'Variable',      [14]  = 'Constant',       [15]  = 'String',
  [16]  = 'Number',        [17]  = 'Boolean',        [18]  = 'Array',
  [19]  = 'Object',        [20]  = 'Key',            [21]  = 'Null',
  [22]  = 'EnumMember',    [23]  = 'Struct',         [24]  = 'Event',
  [25]  = 'Operator',      [26]  = 'TypeParameter',  [255] = 'Macro',
}

local function setup_highlights()
  for _, name in pairs(kind_names) do
    vim.api.nvim_set_hl(0, 'NavicIcons' .. name, { link = 'CmpItemKind' .. name, default = true })
  end
  vim.api.nvim_set_hl(0, 'NavicText', { link = 'Normal', default = true })
  vim.api.nvim_set_hl(0, 'NavicSeparator', { link = 'Comment', default = true })
end

local separator = '%#NavicSeparator# > %*'

local function render_part(sym)
  local name = kind_names[sym.kind] or 'Text'
  local icon = kind_icons[sym.kind] or ''
  return '%#NavicIcons' .. name .. '#' .. icon .. '%#NavicText#' .. sym.name .. '%*'
end

local function find_in_symbols(symbols, line, col)
  local result = {}
  for _, sym in ipairs(symbols) do
    local r = sym.range
    if r then
      local sl, sc = r.start.line, r.start.character
      local el, ec = r['end'].line, r['end'].character
      if (line > sl or (line == sl and col >= sc)) and (line < el or (line == el and col <= ec)) then
        table.insert(result, render_part(sym))
        if sym.children and #sym.children > 0 then
          vim.list_extend(result, find_in_symbols(sym.children, line, col))
        end
        break
      end
    end
  end
  return result
end

local function update(buf)
  local data = cache[buf]
  if not data or not data.symbols then
    return
  end
  local ok, cursor = pcall(vim.api.nvim_win_get_cursor, 0)
  if not ok then
    return
  end
  local parts = find_in_symbols(data.symbols, cursor[1] - 1, cursor[2])
  data.location = table.concat(parts, separator)
end

M._find_in_symbols = find_in_symbols
M._render_part = render_part

function M.get_location()
  local buf = vim.api.nvim_get_current_buf()
  local data = cache[buf]
  if not data or not data.location or data.location == '' then
    return ''
  end
  return data.location
end

function M.setup()
  setup_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('UserNavicHL', { clear = true }),
    callback = setup_highlights,
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserNavic', { clear = true }),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client or not client:supports_method 'textDocument/documentSymbol' then
        return
      end

      cache[ev.buf] = cache[ev.buf] or {}

      local function fetch()
        client:request('textDocument/documentSymbol', {
          textDocument = vim.lsp.util.make_text_document_params(ev.buf),
        }, function(err, result)
          if err or not result then
            return
          end
          cache[ev.buf] = cache[ev.buf] or {}
          cache[ev.buf].symbols = result
          update(ev.buf)
        end, ev.buf)
      end

      fetch()

      vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
        buffer = ev.buf,
        callback = fetch,
      })
      vim.api.nvim_create_autocmd('CursorMoved', {
        buffer = ev.buf,
        callback = function()
          update(ev.buf)
        end,
      })
      vim.api.nvim_create_autocmd('BufDelete', {
        buffer = ev.buf,
        once = true,
        callback = function()
          cache[ev.buf] = nil
        end,
      })
    end,
  })

  vim.o.winbar = "%{%v:lua.require'user.navic'.get_location()%}"
end

return M
