local octo_string = 'Octo: '
return {
  'pwntester/octo.nvim',
  -- dev = true,
  keys = { { '<leader>o', '<cmd>Octo<cr>', desc = 'Octo menu' } },
  cmd = 'Octo',
  -- dependencies = {
  --   'nvim-lua/plenary.nvim',
  --   'nvim-telescope/telescope.nvim',
  -- },
  opts = {
    use_local_fs = true, -- use local files on right side of reviews
    enable_builtin = true, -- shows a list of builtin actions when no action is provided
    default_merge_method = 'squash',
    default_delete_branch = true, -- whether to delete branch when merging pull request with either `Octo pr merge` or from picker (can be overridden with `delete`/`nodelete` argument to `Octo pr merge`)
    picker = 'fzf-lua',
    picker_config = {
      use_emojis = true,
    },
    users = 'assignable', -- Users for assignees or reviewers. Values: "search" | "mentionable" | "assignable"
    pull_requests = {
      use_branch_name_as_title = true, -- sets branch name to be the name for the PR
    },
    mappings = {
      notification = {
        read = { lhs = '<C-r>' },
        done = { lhs = '<C-d>' },
        unsubscribe = { lhs = '<C-u>' },
      },
    },
  },
  config = function(_, opts)
    local octo_config = require 'octo.config'
    local default_opts = octo_config.get_default_values()
    for _, actions in pairs(default_opts.mappings) do
      for _, details in pairs(actions) do
        if details.desc then
          details.desc = octo_string .. details.desc
        end
      end
    end
    -- require('octo').setup(opts)
    -- setup octo and merge opts with default opts
    require('octo').setup(vim.tbl_deep_extend('force', default_opts, opts))
  end,
  init = function()
    -- keymap <leader>gk to open fzf.lua's keymaps with a ready prompt for
    -- "Octo: " to see all octo keymaps when you press <leader>gk
    vim.keymap.set('n', '<leader>gk', function()
      require('fzf-lua').keymaps { query = octo_string }
    end, { desc = 'Octo: Keymaps' })
  end,
}
