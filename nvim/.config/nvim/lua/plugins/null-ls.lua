local M = {
  'nvimtools/none-ls.nvim',
  lazy = true,
  dependencies = {
    'gbprod/none-ls-shellcheck.nvim',
  },
}
M.config = function()
  local null_ls = require 'null-ls'

  -- null-ls
  null_ls.setup {
    debug = true,
    sources = {
      null_ls.builtins.code_actions.gitsigns,
      require('user.lsp.code-actions').revision_branch_comment,
      require('user.lsp.code-actions').toggle_function_params,
      require('user.lsp.code-actions').library_current_branch,
      require('user.lsp.code-actions').selene_ignore_diagnostic,
      require('user.lsp.code-actions').markdownlint_disable_diagnostic,
      require 'none-ls-shellcheck.code_actions',
      null_ls.builtins.hover.printenv,
    },
  }
end

return M
