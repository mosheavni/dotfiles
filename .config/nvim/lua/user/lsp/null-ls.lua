local default_on_attach = require('user.lsp.on-attach').default
local status_ok, null_ls = pcall(require, 'null-ls')
if not status_ok then
  return vim.notify 'Module null-ls not installed'
end
local helpers = require 'null-ls.helpers'

-- null-ls
local sh_extra_fts = { 'bash', 'zsh' }
null_ls.setup {
  on_attach = default_on_attach,
  debug = true,
  sources = {
    null_ls.builtins.code_actions.shellcheck.with {
      extra_filetypes = sh_extra_fts,
    },
    null_ls.builtins.code_actions.gitsigns,
    null_ls.builtins.code_actions.eslint_d,
    null_ls.builtins.diagnostics.ansiblelint,
    null_ls.builtins.diagnostics.hadolint,
    -- null_ls.builtins.diagnostics.npm_groovy_lint,
    null_ls.builtins.diagnostics.vint,
    null_ls.builtins.diagnostics.shellcheck.with {
      extra_filetypes = sh_extra_fts,
    },
    null_ls.builtins.diagnostics.eslint_d,
    null_ls.builtins.formatting.black,
    null_ls.builtins.formatting.eslint_d,
    null_ls.builtins.formatting.fixjson,
    null_ls.builtins.formatting.npm_groovy_lint,
    -- null_ls.builtins.formatting.prettierd,
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.formatting.terraform_fmt,
    null_ls.builtins.formatting.shfmt.with {
      extra_filetypes = sh_extra_fts,
    },
  },
}

local null_ls_stop = function()
  local null_ls_client
  for _, client in ipairs(vim.lsp.get_active_clients()) do
    if client.name == 'null-ls' then
      null_ls_client = client
    end
  end
  if not null_ls_client then
    return
  end

  null_ls_client.stop()
end

vim.api.nvim_create_user_command('NullLsStop', null_ls_stop, {})
