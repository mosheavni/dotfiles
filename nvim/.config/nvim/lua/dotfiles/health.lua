local M = {}

-- tool name → binary to check in PATH
local tools = {
  { name = 'actionlint', binary = 'actionlint', install = 'brew install actionlint' },
  { name = 'aws', binary = 'aws', install = 'asdf install awscli' },
  { name = 'bash-language-server', binary = 'bash-language-server', install = 'brew install bash-language-server' },
  { name = 'black', binary = 'black', install = 'pip install black' },
  { name = 'checkmake', binary = 'checkmake', install = 'brew bundle --file=~/.dotfiles/Brewfile' },
  { name = 'codespell', binary = 'codespell', install = 'pip install codespell' },
  { name = 'css-lsp', binary = 'vscode-css-language-server', install = 'npm install -g vscode-langservers-extracted' },
  { name = 'cssmodules-language-server', binary = 'cssmodules-language-server', install = 'npm install -g cssmodules-language-server' },
  { name = 'dclint', binary = 'dclint', install = 'npm install -g dclint' },
  { name = 'docker-compose-language-service', binary = 'docker-compose-langserver', install = 'brew install docker-compose-langserver' },
  { name = 'dockerfile-language-server', binary = 'docker-langserver', install = 'npm install -g dockerfile-language-server-nodejs' },
  { name = 'figlet', binary = 'figlet', install = 'brew install figlet' },
  { name = 'gh', binary = 'gh', install = 'brew install gh' },
  { name = 'gitleaks', binary = 'gitleaks', install = 'brew install gitleaks' },
  { name = 'gofmt', binary = 'gofmt', install = 'asdf install golang' },
  { name = 'golangci-lint', binary = 'golangci-lint', install = 'brew install golangci-lint' },
  { name = 'golangci-lint-langserver', binary = 'golangci-lint-langserver', install = 'brew install golangci-lint-langserver' },
  { name = 'gopls', binary = 'gopls', install = 'brew install gopls' },
  { name = 'groovy-language-server', binary = 'groovy-language-server' },
  { name = 'hadolint', binary = 'hadolint', install = 'brew install hadolint' },
  { name = 'helm-ls', binary = 'helm_ls', install = 'brew install helm-ls' },
  { name = 'html-lsp', binary = 'vscode-html-language-server', install = 'npm install -g vscode-langservers-extracted' },
  { name = 'isort', binary = 'isort', install = 'pip install isort' },
  { name = 'jinja-lsp', binary = 'jinja-lsp', install = 'brew bundle --file=~/.dotfiles/Brewfile' },
  { name = 'json-lsp', binary = 'vscode-json-language-server', install = 'npm install -g vscode-langservers-extracted' },
  { name = 'lua-language-server', binary = 'lua-language-server', install = 'brew install lua-language-server' },
  { name = 'luacheck', binary = 'luacheck', install = 'brew install luacheck' },
  { name = 'markdownlint', binary = 'markdownlint', install = 'npm install -g markdownlint-cli' },
  { name = 'npm-groovy-lint', binary = 'npm-groovy-lint', install = 'npm install -g npm-groovy-lint' },
  { name = 'op', binary = 'op', install = 'brew install --cask 1password-cli' },
  { name = 'openssl', binary = 'openssl', install = 'brew install openssl' },
  { name = 'prettierd', binary = 'prettierd', install = 'npm install -g @fsouza/prettierd' },
  { name = 'pyright', binary = 'pyright', install = 'pip install pyright' },
  { name = 'ripgrep', binary = 'rg', install = 'asdf install ripgrep' },
  { name = 'ruff', binary = 'ruff', install = 'pip install ruff' },
  { name = 'selene', binary = 'selene', install = 'brew install selene' },
  { name = 'shellcheck', binary = 'shellcheck', install = 'brew install shellcheck' },
  { name = 'shfmt', binary = 'shfmt', install = 'brew install shfmt' },
  { name = 'stylua', binary = 'stylua', install = 'brew install stylua' },
  { name = 'terraform', binary = 'terraform', install = 'asdf install terraform' },
  { name = 'terraform-ls', binary = 'terraform-ls', install = 'brew install hashicorp/tap/terraform-ls' },
  { name = 'terragrunt', binary = 'terragrunt', install = 'asdf install terragrunt' },
  { name = 'tombi', binary = 'tombi', install = 'brew install tombi' },
  { name = 'trivy', binary = 'trivy', install = 'brew install aquasecurity/trivy/trivy' },
  { name = 'typescript-language-server', binary = 'typescript-language-server', install = 'brew install typescript-language-server' },
  { name = 'vim-language-server', binary = 'vim-language-server', install = 'npm install -g vim-language-server' },
  { name = 'vint', binary = 'vint', install = 'pip install vim-vint' },
  { name = 'vtsls', binary = 'vtsls', install = 'npm install -g @vtsls/language-server' },
  { name = 'wezterm', binary = 'wezterm', install = 'brew install --cask wezterm@nightly' },
  { name = 'zizmor', binary = 'zizmor', install = 'brew install zizmor' },
  { name = 'xmllint', binary = 'xmllint', install = 'brew install libxml2' },
  { name = 'yaml-language-server', binary = 'yaml-language-server', install = 'brew install yaml-language-server' },
}

M.check = function()
  vim.health.start 'External tools'
  for _, tool in ipairs(tools) do
    if vim.fn.executable(tool.binary) == 1 then
      vim.health.ok(tool.name)
    else
      vim.health.error(tool.name .. ' (' .. tool.binary .. ') not found', tool.install and { tool.install })
    end
  end
end

return M
