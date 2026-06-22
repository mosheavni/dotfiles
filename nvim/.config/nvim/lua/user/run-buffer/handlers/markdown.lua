-- Markdown preview: detached mdserve.
return {
  ft = 'markdown',
  ---@type RunHandler
  handler = {
    resolve = function(ctx)
      local job_id = vim.fn.jobstart({ 'mdserve', '--open', ctx.file_name }, { detach = true })
      if job_id <= 0 then
        vim.notify('Failed to start mdserve', vim.log.levels.ERROR, { title = 'run-buffer' })
      end
      return { spawn = false }
    end,
  },
}
