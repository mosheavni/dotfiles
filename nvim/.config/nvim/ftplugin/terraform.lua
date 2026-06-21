-- Prompt to run `terraform init` when the file's directory has no `.terraform`
-- directory yet. Dedup per directory so multiple .tf files don't re-prompt.
-- Use the real buffer name (not `%:p:h`, which falls back to cwd for nameless
-- buffers like fzf previews) and only act on on-disk file buffers.
require('user.terraform-docs').setup {}
vim.bo.commentstring = '# %s'

local bufname = vim.api.nvim_buf_get_name(0)
local is_real_file = bufname ~= '' and vim.bo.buftype == '' and vim.fn.filereadable(bufname) == 1
local dir = is_real_file and vim.fn.fnamemodify(bufname, ':p:h') or ''

_G.__tf_init_prompted = _G.__tf_init_prompted or {}
local prompted = _G.__tf_init_prompted

if dir ~= '' and not prompted[dir] and vim.fn.isdirectory(dir .. '/.terraform') == 0 then
  prompted[dir] = true
  vim.schedule(function()
    local select_opts = {
      title = 'No .terraform in ' .. vim.fn.fnamemodify(dir, ':~'),
      prompt = 'Run "terraform init"?❯ ',
    }
    vim.ui.select({ 'Yes', 'No' }, select_opts, function(choice)
      if choice ~= 'Yes' then
        return
      end
      local terminal = require 'user.terminal'
      local buf, job_id = terminal.open { cwd = dir, name = 'terraform init', focus = false }
      if job_id and buf then
        vim.schedule(function()
          terminal.send('terraform init', { buf = buf })
        end)
      end
    end)
  end)
end
