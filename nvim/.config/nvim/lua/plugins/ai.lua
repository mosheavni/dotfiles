local node_bin = '/opt/homebrew/opt/node/bin/node'
vim.pack.add {
  'https://github.com/zbirenbaum/copilot.lua',
  'https://github.com/HakonHarnes/img-clip.nvim',
  'https://github.com/yetone/avante.nvim',
}

local ai_keymap = '<leader>ccc'

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

  require('avante').setup {
    provider = 'cursor',
    mode = 'agentic',
    acp_providers = {
      cursor = {
        command = os.getenv 'HOME' .. '/.local/bin/agent',
        args = { 'acp' },
        auth_method = 'cursor_login',
        env = {
          HOME = os.getenv 'HOME',
          PATH = os.getenv 'PATH',
        },
      },
    },
  }

  vim.keymap.set({ 'n', 'v', 'i' }, ai_keymap, function()
    require('avante').toggle()
  end, { desc = 'Toggle Avante' })
  vim.keymap.set('n', '<leader>ccs', function()
    require('avante.api').stop()
  end, { desc = 'Abort current execution' })
  vim.keymap.set({ 'n', 'v' }, "<C-'>", function()
    require('avante.api').add_selected_file(vim.fn.expand '%:p')
  end, { desc = 'Add current file to Avante context' })
  vim.keymap.set({ 'n', 'v', 'i' }, '<C-,>', function()
    require('avante.api').ask { new_chat = true }
  end, { desc = 'New Avante Session' })

  require('user.menu').add_actions('AI', {
    ['Toggle Avante (' .. ai_keymap .. ')'] = function()
      require('avante').toggle()
    end,
    ['New Avante Session (<C-,>)'] = function()
      require('avante.api').ask { new_chat = true }
    end,
    ["Add current file to Avante context (<C-'>)"] = function()
      require('avante.api').add_selected_file(vim.fn.expand '%:p')
    end,
  })
end
