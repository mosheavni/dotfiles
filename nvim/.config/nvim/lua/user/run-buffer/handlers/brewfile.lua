-- Brewfile: install missing deps via brew bundle (no upgrades).
return {
  ft = 'brewfile',
  ---@type RunHandler
  handler = {
    resolve = function(ctx)
      return {
        cmd = 'brew bundle --file=' .. vim.fn.shellescape(ctx.file_name) .. ' --no-upgrade',
        spawn = true,
        cwd = vim.fn.fnamemodify(ctx.file_name, ':p:h'),
      }
    end,
  },
}
