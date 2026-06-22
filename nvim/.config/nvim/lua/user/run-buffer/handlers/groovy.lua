-- Jenkinsfile: validate via user.jenkins-validate; no shell command.
local M = {}

M.ft = 'groovy'

---@type RunHandler
M.handler = {
  resolve = function(_, on_done)
    require('user.jenkins-validate').validate()
    on_done { spawn = false }
  end,
}

return M
