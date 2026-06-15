local M = {}

-- tool name → binary to check in PATH
local tools = {
  { name = 'actionlint', binary = 'actionlint' },
  { name = 'aws', binary = 'aws' },
  { name = 'bash-language-server', binary = 'bash-language-server' },
  { name = 'black', binary = 'black' },
  { name = 'checkmake', binary = 'checkmake' },
  { name = 'codespell', binary = 'codespell' },
  { name = 'css-lsp', binary = 'vscode-css-language-server' },
  { name = 'cssmodules-language-server', binary = 'cssmodules-language-server' },
  { name = 'dclint', binary = 'dclint' },
  { name = 'docker-compose-language-service', binary = 'docker-compose-langserver' },
  { name = 'dockerfile-language-server', binary = 'docker-langserver' },
  { name = 'figlet', binary = 'figlet' },
  { name = 'gh', binary = 'gh' },
  { name = 'gitleaks', binary = 'gitleaks' },
  { name = 'gofmt', binary = 'gofmt' },
  { name = 'golangci-lint', binary = 'golangci-lint' },
  { name = 'golangci-lint-langserver', binary = 'golangci-lint-langserver' },
  { name = 'gopls', binary = 'gopls' },
  { name = 'groovy-language-server', binary = 'groovy-language-server' },
  { name = 'hadolint', binary = 'hadolint' },
  { name = 'helm-ls', binary = 'helm_ls' },
  { name = 'html-lsp', binary = 'vscode-html-language-server' },
  { name = 'isort', binary = 'isort' },
  { name = 'jinja-lsp', binary = 'jinja-lsp' },
  { name = 'json-lsp', binary = 'vscode-json-language-server' },
  { name = 'lua-language-server', binary = 'lua-language-server' },
  { name = 'luacheck', binary = 'luacheck' },
  { name = 'markdownlint', binary = 'markdownlint' },
  { name = 'npm-groovy-lint', binary = 'npm-groovy-lint' },
  { name = 'op', binary = 'op' },
  { name = 'openssl', binary = 'openssl' },
  { name = 'prettierd', binary = 'prettierd' },
  { name = 'pyright', binary = 'pyright' },
  { name = 'ripgrep', binary = 'rg' },
  { name = 'ruff', binary = 'ruff' },
  { name = 'selene', binary = 'selene' },
  { name = 'shellcheck', binary = 'shellcheck' },
  { name = 'shfmt', binary = 'shfmt' },
  { name = 'stylua', binary = 'stylua' },
  { name = 'terraform', binary = 'terraform' },
  { name = 'terraform-ls', binary = 'terraform-ls' },
  { name = 'terragrunt', binary = 'terragrunt' },
  { name = 'tombi', binary = 'tombi' },
  { name = 'trivy', binary = 'trivy' },
  { name = 'typescript-language-server', binary = 'typescript-language-server' },
  { name = 'vim-language-server', binary = 'vim-language-server' },
  { name = 'vint', binary = 'vint' },
  { name = 'vtsls', binary = 'vtsls' },
  { name = 'wezterm', binary = 'wezterm' },
  { name = 'xmllint', binary = 'xmllint' },
  { name = 'yaml-language-server', binary = 'yaml-language-server' },
}

local function check_python_module(mod)
  local result = vim.system({ 'python3', '-c', 'import ' .. mod }):wait()
  return result.code == 0
end

M.check = function()
  vim.health.start 'External tools'
  for _, tool in ipairs(tools) do
    if tool.python_module then
      if check_python_module(tool.python_module) then
        vim.health.ok(tool.name .. ' (python module)')
      else
        vim.health.error(tool.name .. ' not found', { 'pip install ' .. tool.python_module })
      end
    elseif vim.fn.executable(tool.binary) == 1 then
      vim.health.ok(tool.name)
    else
      vim.health.error(tool.name .. ' (' .. tool.binary .. ') not found')
    end
  end
end

return M
