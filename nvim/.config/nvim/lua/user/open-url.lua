local M = {}

M.url_prefix = 'https://github.com'

M.open_url_under_cursor = function()
  local cword = vim.fn.expand '<cfile>'

  ---@diagnostic disable-next-line: param-type-mismatch
  local url = string.gsub(cword, [[[%w%-%.]+/[%w%-%.]+]], '%1')
  -- Remove surronding quotes if exist
  url = string.gsub(url, [[^["'](.*)["']$]], '%1')

  -- If string starts with https://
  if string.match(url, [[^https?://.*]]) then
    return vim.ui.open(url)
  end

  -- If string matches `user/repo`
  if string.match(url, [[.*/.*]]) then
    local suffix = ''
    -- check if string has @
    if string.match(url, [[.*@.*]]) then
      suffix = '/tree/' .. string.gsub(url, [[.*@(.*)]], '%1')
      url = string.gsub(url, [[(.*)@.*]], '%1')
    end

    return vim.ui.open(M.url_prefix .. '/' .. url .. suffix)
  end
end

return M
