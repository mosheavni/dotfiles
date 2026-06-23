local M = {}

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

M.separator = '%#NavicSeparator# > %*'

function M.safe_name(name)
  name = name:gsub('%%', '%%%%')
  name = name:gsub('\n', ' ')
  return name
end

function M.render_part(sym)
  local hl_name = kind_names[sym.kind] or 'Text'
  local icon = kind_icons[sym.kind] or ''
  return '%#NavicIcons' .. hl_name .. '#' .. icon .. '%#NavicText#' .. M.safe_name(sym.name) .. '%*'
end

function M.find_in_symbols(symbols, line, col)
  local result = {}
  for _, sym in ipairs(symbols) do
    local r = sym.range
    if r then
      local sl, sc = r.start.line, r.start.character
      local el, ec = r['end'].line, r['end'].character
      if (line > sl or (line == sl and col >= sc)) and (line < el or (line == el and col <= ec)) then
        table.insert(result, M.render_part(sym))
        if sym.children and #sym.children > 0 then
          vim.list_extend(result, M.find_in_symbols(sym.children, line, col))
        end
        break
      end
    end
  end
  return result
end

return M
