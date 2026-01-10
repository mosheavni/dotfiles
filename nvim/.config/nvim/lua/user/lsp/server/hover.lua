-- Hover providers for the user LSP server

local M = {}

--- Get the word at a specific position in the buffer
---@param bufnr number
---@param line number 0-indexed line
---@param character number 0-indexed character
---@return string
local function get_word_at_position(bufnr, line, character)
  local line_content = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
  if not line_content then
    return ''
  end

  -- Find word boundaries around the character position
  local col = character + 1 -- Convert to 1-indexed
  local word_start = col
  local word_end = col

  -- Find start of word
  while word_start > 1 do
    local char = line_content:sub(word_start - 1, word_start - 1)
    if not char:match '[%w_]' then
      break
    end
    word_start = word_start - 1
  end

  -- Find end of word
  while word_end <= #line_content do
    local char = line_content:sub(word_end, word_end)
    if not char:match '[%w_]' then
      break
    end
    word_end = word_end + 1
  end

  return line_content:sub(word_start, word_end - 1)
end

-- Check if filetype is a shell type
local function is_shell_filetype(filetype)
  return filetype == 'sh' or filetype == 'bash' or filetype == 'zsh'
end

-- TLDR hover: show tldr documentation for commands
local function tldr_hover(context, word)
  if not is_shell_filetype(context.filetype) then
    return nil
  end

  -- Run tldr command
  local result = vim.fn.system { 'tldr', '--raw', word }
  if vim.v.shell_error ~= 0 then
    return nil
  end

  -- Trim whitespace
  result = result:gsub('^%s+', ''):gsub('%s+$', '')
  if result == '' then
    return nil
  end

  return {
    contents = {
      kind = 'markdown',
      value = result,
    },
  }
end

-- Printenv hover: show environment variable value
local function printenv_hover(context, word)
  if not is_shell_filetype(context.filetype) then
    return nil
  end

  local value = vim.env[word]
  if value then
    return {
      contents = {
        kind = 'markdown',
        value = string.format('**%s**\n```\n%s\n```', word, value),
      },
    }
  end

  return nil
end

-- List of hover providers (order matters - first match wins)
local hover_providers = {
  printenv_hover,
  tldr_hover,
}

--- Get hover information for the given LSP params
---@param params table LSP hover params
---@return table|nil hover response
function M.get_hover(params)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
  local line = params.position.line
  local character = params.position.character
  local filetype = vim.bo[bufnr].filetype

  local word = get_word_at_position(bufnr, line, character)
  if word == '' then
    return nil
  end

  local context = {
    bufnr = bufnr,
    filetype = filetype,
    position = params.position,
  }

  for _, provider in ipairs(hover_providers) do
    local result = provider(context, word)
    if result then
      return result
    end
  end

  return nil
end

return M
