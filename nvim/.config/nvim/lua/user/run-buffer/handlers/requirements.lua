-- requirements.txt: install pinned deps via pip.
return {
  ft = 'requirements',
  ---@type RunHandler
  handler = {
    resolve = function(ctx)
      return {
        cmd = 'pip install -r ' .. vim.fn.shellescape(ctx.file_name),
        spawn = true,
      }
    end,
  },
}
