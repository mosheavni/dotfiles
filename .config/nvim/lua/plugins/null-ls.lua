local M = {
  'nvimtools/none-ls.nvim',
  lazy = true,
  dependencies = {
    'jay-babu/mason-null-ls.nvim',
  },
}
M.config = function()
  local null_ls = require 'null-ls'
  local default_on_attach = require('user.lsp.on-attach').default

  -- null-ls
  local sh_extra_fts = { 'bash', 'zsh' }
  null_ls.setup {
    on_attach = default_on_attach,
    debug = true,
    sources = {
      require('user.lsp.code-actions').revision_branch_comment,
      require('user.lsp.code-actions').toggle_function_params,
      null_ls.builtins.code_actions.shellcheck.with {
        extra_filetypes = { 'bash' },
      },
      -- null_ls.builtins.code_actions.gitsigns,
      null_ls.builtins.code_actions.eslint_d,
      require 'typescript.extensions.null-ls.code-actions',
      null_ls.builtins.diagnostics.ansiblelint,
      null_ls.builtins.diagnostics.hadolint,
      null_ls.builtins.diagnostics.markdownlint,
      null_ls.builtins.diagnostics.vint,
      -- null_ls.builtins.diagnostics.shellcheck.with {
      --   extra_filetypes = { 'bash' },
      -- },
      -- null_ls.builtins.diagnostics.eslint_d,
      null_ls.builtins.formatting.black,
      -- null_ls.builtins.formatting.eslint_d,
      null_ls.builtins.formatting.markdownlint,
      null_ls.builtins.formatting.npm_groovy_lint,
      null_ls.builtins.formatting.prettierd,
      null_ls.builtins.formatting.stylua,
      null_ls.builtins.formatting.terraform_fmt,
      null_ls.builtins.formatting.shfmt.with {
        extra_filetypes = sh_extra_fts,
      },
    },
  }
  require('mason-null-ls').setup {
    ---@diagnostic disable-next-line: assign-type-mismatch
    ensure_installed = nil,
    automatic_installation = true,
  }
end

return M
