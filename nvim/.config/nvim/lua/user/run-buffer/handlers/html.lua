-- HTML: open in the system browser via vim.ui.open.
return {
  ft = 'html',
  ---@type RunHandler
  handler = {
    resolve = function(ctx)
      vim.ui.open(ctx.file_name)
      return { spawn = false }
    end,
  },
}
