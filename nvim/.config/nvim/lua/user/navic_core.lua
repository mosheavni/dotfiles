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

-- -1 = before, 0 = in range, 1 = after (vim 1-indexed cursor + scope)
local function in_range(cursor_pos, range)
  local line = cursor_pos[1]
  local char = cursor_pos[2]

  if line < range['start'].line then
    return -1
  elseif line > range['end'].line then
    return 1
  end

  if line == range['start'].line and char < range['start'].character then
    return -1
  elseif line == range['end'].line and char > range['end'].character then
    return 1
  end

  return 0
end

local function dfs(curr_symbol_layer, parent_node)
  if #curr_symbol_layer == 0 then
    return
  end

  parent_node.children = {}

  for _, val in ipairs(curr_symbol_layer) do
    local scope = val.range
    scope['start'].line = scope['start'].line + 1
    scope['end'].line = scope['end'].line + 1

    local curr_parsed_symbol = {
      name = val.name or ' ',
      scope = scope,
      kind = val.kind or 0,
      parent = parent_node,
    }

    if val.children then
      dfs(val.children, curr_parsed_symbol)
    end

    table.insert(parent_node.children, curr_parsed_symbol)
  end

  table.sort(parent_node.children, function(a, b)
    if b.scope.start.line == a.scope.start.line then
      return b.scope.start.character > a.scope.start.character
    end
    return b.scope.start.line > a.scope.start.line
  end)

  for i = 1, #parent_node.children, 1 do
    parent_node.children[i].prev = parent_node.children[i - 1]
    parent_node.children[i].next = parent_node.children[i + 1]
    parent_node.children[i].index = i
  end
end

function M.parse(symbols)
  local root_node = {
    is_root = true,
    index = 1,
    scope = {
      start = { line = -10, character = 0 },
      ['end'] = { line = 2147483640, character = 0 },
    },
  }

  if #symbols >= 1 and symbols[1].range ~= nil then
    dfs(symbols, root_node)
  end

  return root_node
end

function M.update_context(tree, old_context, cursor_pos)
  local new_context = {}
  local curr = tree

  if curr == nil then
    return new_context
  end

  if curr.is_root then
    table.insert(new_context, curr)
  end

  for _, context in ipairs(old_context) do
    if curr == nil then
      break
    end
    if
      in_range(cursor_pos, context.scope) == 0
      and curr.children ~= nil
      and curr.children[context.index] ~= nil
      and context.name == curr.children[context.index].name
      and context.kind == curr.children[context.index].kind
    then
      table.insert(new_context, curr.children[context.index])
      curr = curr.children[context.index]
    else
      break
    end
  end

  while curr.children ~= nil do
    local go_deeper = false
    local l = 1
    local h = #curr.children
    while l <= h do
      -- selene: allow(undefined_variable)
      local m = bit.rshift(l + h, 1)
      local comp = in_range(cursor_pos, curr.children[m].scope)
      if comp == -1 then
        h = m - 1
      elseif comp == 1 then
        l = m + 1
      else
        table.insert(new_context, curr.children[m])
        curr = curr.children[m]
        go_deeper = true
        break
      end
    end
    if not go_deeper then
      break
    end
  end

  return new_context
end

function M.format_context(context)
  local parts = {}
  for _, node in ipairs(context) do
    if not node.is_root then
      table.insert(parts, M.render_part(node))
    end
  end
  return parts
end

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
  local tree = M.parse(symbols)
  local context = M.update_context(tree, {}, { line + 1, col })
  return M.format_context(context)
end

return M
