local default_on_attach = require 'user.lsp.on-attach'
local status_ok, null_ls = pcall(require, 'null-ls')
if not status_ok then
  return vim.notify 'Module null-ls not installed'
end

-- null-ls
local sh_extra_fts = { 'bash', 'zsh' }
null_ls.setup {
  on_attach = default_on_attach,
  debug = true,
  sources = {
    -- null_ls.builtins.code_actions.eslint_d,
    null_ls.builtins.code_actions.refactoring,
    -- null_ls.builtins.diagnostics.eslint_d,
    -- null_ls.builtins.diagnostics.markdownlint,
    -- null_ls.builtins.diagnostics.write_good,
    -- null_ls.builtins.formatting.eslint_d,
    null_ls.builtins.formatting.fixjson,
    -- null_ls.builtins.formatting.markdownlint,
    null_ls.builtins.code_actions.shellcheck.with {
      extra_filetypes = sh_extra_fts,
    },
    null_ls.builtins.diagnostics.ansiblelint,
    null_ls.builtins.diagnostics.hadolint,
    null_ls.builtins.diagnostics.pylint,
    null_ls.builtins.diagnostics.shellcheck.with {
      extra_filetypes = sh_extra_fts,
    },
    null_ls.builtins.diagnostics.yamllint,
    null_ls.builtins.formatting.black,
    null_ls.builtins.formatting.prettier,
    null_ls.builtins.formatting.prettierd,
    null_ls.builtins.formatting.stylua.with {
      extra_args = { '--config-path', vim.fn.expand '~' .. '/stylua.toml' },
    },
    null_ls.builtins.formatting.shfmt.with {
      extra_filetypes = sh_extra_fts,
    },
  },
}
