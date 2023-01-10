local M = {
  'jose-elias-alvarez/null-ls.nvim',
  lazy = true,
}
M.config = function()
  local null_ls = require 'null-ls'
  local default_on_attach = require('user.lsp.on-attach').default

  -- null-ls
  local sh_extra_fts = { 'bash', 'zsh' }
  null_ls.setup {
    on_attach = default_on_attach,
    debug = false,
    sources = {
      null_ls.builtins.code_actions.shellcheck.with {
        extra_filetypes = sh_extra_fts,
      },
      null_ls.builtins.code_actions.gitsigns,
      null_ls.builtins.code_actions.eslint_d,
      require 'typescript.extensions.null-ls.code-actions',
      null_ls.builtins.diagnostics.ansiblelint,
      null_ls.builtins.diagnostics.hadolint,
      null_ls.builtins.diagnostics.markdownlint,
      null_ls.builtins.diagnostics.vint,
      null_ls.builtins.diagnostics.shellcheck.with {
        extra_filetypes = sh_extra_fts,
      },
      null_ls.builtins.diagnostics.eslint_d,
      null_ls.builtins.formatting.black,
      null_ls.builtins.formatting.eslint_d,
      null_ls.builtins.formatting.fixjson,
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
end

return M
