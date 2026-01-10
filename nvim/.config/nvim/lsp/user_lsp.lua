-- User LSP configuration (Neovim 0.11+ convention)
-- Server implementation: lua/user/lsp/server/

local server = require 'user.lsp.server'

return {
  name = server.config.name,
  cmd = server.create_server(),
  filetypes = server.config.filetypes or {
    'bash',
    'css',
    'dockerfile',
    'go',
    'groovy',
    'helm',
    'html',
    'javascript',
    'json',
    'lua',
    'markdown',
    'python',
    'sh',
    'terraform',
    'typescript',
    'vim',
    'yaml',
    'zsh',
  },
  commands = server.commands,
}
