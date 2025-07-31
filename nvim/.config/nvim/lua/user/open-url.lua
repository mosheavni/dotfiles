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

  -- if not cword, find all http(s) links in the file and use vim.ui.select to choose one
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local links = {}
  for i, line in ipairs(lines) do
    for link in string.gmatch(line, [[(https?://[%w%.%-_/]+)]]) do
      table.insert(links, { line = i, link = link })
    end
  end

  if #links == 0 then
    return vim.notify('No links found in the file', vim.log.levels.WARN)
  end

  vim.ui.select(links, {
    prompt = 'Select a link to open:',
    format_item = function(item)
      return item.line .. ':🔗 ' .. item.link
    end,
  }, function(selected)
    if selected then
      vim.ui.open(selected.link)
    end
  end)
end

return M
