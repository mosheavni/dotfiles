local M = {}

local uname = vim.uv.os_uname()

M.is_mac = uname.sysname == 'Darwin'
M.is_linux = uname.sysname == 'Linux'
M.is_windows = uname.sysname == 'Windows_NT'
M.is_wsl = string.find(uname.release, 'microsoft') ~= nil

M.url_prefix = 'https://github.com'
M.keymap_lhs = 'gx'
M.open_cmd = nil

M.open_url = function(url)
  if M.open_cmd ~= nil then
    vim.cmd('silent !' .. M.open_cmd .. ' ' .. url)
  elseif M.is_windows then
    vim.cmd([[:execute 'silent !start ]] .. url .. "'")
  elseif M.is_wsl then
    vim.cmd([[:execute 'silent !powershell.exe start ]] .. url .. "'")
  elseif M.is_mac then
    vim.cmd([[:execute 'silent !open ]] .. url .. "'")
  elseif M.is_linux then
    vim.cmd([[:execute 'silent !xdg-open ]] .. url .. "'")
  else
    print 'Unknown platform. Cannot open url'
  end
end

M.open_url_under_cursor = function()
  local cword = vim.fn.expand '<cfile>'

  -- Remove surronding quotes if exist
  ---@diagnostic disable-next-line: param-type-mismatch
  local url = string.gsub(cword, [[.*['"](.*)['"].*$]], '%1')

  -- If string starts with https://
  if string.match(url, [[^https://.*]]) then
    return M.open_url(url)
  end

  -- If string matches `user/repo`
  if string.match(url, [[.*/.*]]) then
    local suffix = ''
    -- check if string has @
    if string.match(url, [[.*@.*]]) then
      suffix = '/tree/' .. string.gsub(url, [[.*@(.*)]], '%1')
      url = string.gsub(url, [[(.*)@.*]], '%1')
    end

    return M.open_url(M.url_prefix .. '/' .. url .. suffix)
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
