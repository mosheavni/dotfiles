local M = {
  'nvimtools/none-ls.nvim',
  lazy = true,
  dependencies = {
    'gbprod/none-ls-shellcheck.nvim',
    'jay-babu/mason-null-ls.nvim',
  },
}
M.config = function()
  local null_ls = require 'null-ls'

  -- null-ls
  null_ls.setup {
    debug = true,
    sources = {
      null_ls.builtins.code_actions.gitsigns,
      null_ls.builtins.code_actions.proselint,
      require('user.lsp.code-actions').revision_branch_comment,
      require('user.lsp.code-actions').toggle_function_params,
      require('user.lsp.code-actions').library_current_branch,
      require 'none-ls-shellcheck.code_actions',
      null_ls.builtins.diagnostics.hadolint,
      null_ls.builtins.diagnostics.markdownlint,
      null_ls.builtins.diagnostics.proselint,
      null_ls.builtins.diagnostics.npm_groovy_lint,
      null_ls.builtins.diagnostics.terragrunt_validate,
      null_ls.builtins.diagnostics.selene,
    },
  }
  require('mason-null-ls').setup {
    ---@diagnostic disable-next-line: assign-type-mismatch
    ensure_installed = nil,
    automatic_installation = true,
  }
end

return M
