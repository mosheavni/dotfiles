-- Jenkinsfile: validate via user.jenkins-validate; no shell command.
local M = {}

M.ft = 'groovy'

---@type RunHandler
M.handler = {
  resolve = function()
    require('user.jenkins-validate').validate()
    return { spawn = false }
  end,
}

return M
