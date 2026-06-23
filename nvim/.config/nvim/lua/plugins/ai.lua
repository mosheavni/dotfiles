local node_bin = '/opt/homebrew/opt/node/bin/node'
vim.pack.add {
  'https://github.com/zbirenbaum/copilot.lua',
}

return function()
  require('copilot').setup {
    copilot_node_command = node_bin,
    filetypes = { ['*'] = true },
    panel = {
      enabled = true,
      auto_refresh = false,
      keymap = {
        jump_prev = '[[',
        jump_next = ']]',
        accept = '<CR>',
        refresh = 'gr',
        open = '<M-l>',
      },
    },
    suggestion = {
      auto_trigger = true,
      keymap = { accept = '<M-Enter>' },
    },
  }
end
