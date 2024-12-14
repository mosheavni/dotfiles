local M = {}

M.url_prefix = 'https://github.com'
M.keymap_lhs = 'gx'
M.open_cmd = nil

M.open_url_under_cursor = function()
  local cword = vim.fn.expand '<cfile>'

  -- Remove surronding quotes if exist
  ---@diagnostic disable-next-line: param-type-mismatch
  local url = string.gsub(cword, [[.*['"](.*)['"].*$]], '%1')

  -- If string starts with https://
  if string.match(url, [[^https://.*]]) then
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

M.setup = function(options)
  if options then
    if options.keymap ~= nil then
      M.keymap_lhs = options.keymap
    end

    if options.url_prefix ~= nil then
      M.url_prefix = options.url_prefix
    end

    if options.open_cmd ~= nil then
      M.open_cmd = options.open_cmd
    end
  end

  local bufnr = vim.api.nvim_get_current_buf()
  vim.keymap.set('n', M.keymap_lhs, function()
    M.open_url_under_cursor()
  end, { buffer = bufnr, silent = true, desc = 'Open plugin url under cursor' })
end

return M
