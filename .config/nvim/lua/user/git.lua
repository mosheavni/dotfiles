local utils = require 'user.utils'

local prnt = function(message)
  require('user.utils').pretty_print(message, 'Git Actions', '')
end

local function run_git(args, message)
  utils.system('git', args, function(c, o, e)
    if c ~= 0 then
      prnt('Failed to ' .. message .. '\nstderr: ' .. (e or ''))
      return
    else
      prnt(msg)
    end
  end)
end
-------------------
-- Git functions --
-------------------
local function get_git_remote(callback)
  vim.system({ 'git', 'remote', '-v' }, { text = true }, function(obj)
    callback(obj.stdout:match '(.-)%s+%(fetch%)')
  end)
end

local M = {
  get_git_remote = get_git_remote,
}
return M
