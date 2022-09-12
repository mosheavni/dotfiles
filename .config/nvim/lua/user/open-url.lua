local utils = require 'user.utils'
local keymap = utils.keymap
local opts = utils.map_opts
local M = {}

local uname = vim.loop.os_uname()

M.is_mac = uname.sysname == 'Darwin'
M.is_linux = uname.sysname == 'Linux'
M.is_windows = uname.sysname == 'Windows_NT'
M.is_wsl = not (string.find(uname.release, 'microsoft') == nil)

M.open_url = function(url)
  if M.is_windows then
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
  local cword = vim.fn.expand '<cWORD>'

  -- Remove surronding quotes if exist
  local url = string.gsub(cword, [[.*['"](.*)['"].*$]], '%1')

  -- If string starts with https://
  if string.match(url, [[^https://.*]]) then
    return M.open_url(url)
  end

  -- If string matches `user/repo`
  if string.match(url, [[.*/.*]]) then
    return M.open_url('https://github.com/' .. url)
  end
end

M.setup = function(options)
  local keymap_lhs = 'gx'
  if options and options.keymap ~= nil then
    keymap_lhs = options.keymap
  end

  keymap('n', keymap_lhs, function()
    M.open_url_under_cursor()
  end, opts.no_remap_silent)
end

return M
