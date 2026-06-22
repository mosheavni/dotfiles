-- Jenkinsfile: validate via user.jenkins-validate; no shell command.
return {
  ft = 'groovy',
  ---@type RunHandler
  handler = {
    resolve = function()
      require('user.jenkins-validate').validate()
      return { spawn = false }
    end,
  },
}
