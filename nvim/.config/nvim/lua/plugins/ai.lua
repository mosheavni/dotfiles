local pack = require 'user.pack.add'
pack.add {
  'https://github.com/zbirenbaum/copilot.lua',
  'https://github.com/ravitemer/mcphub.nvim',
  'https://github.com/carlos-algms/agentic.nvim',
  'https://github.com/HakonHarnes/img-clip.nvim',
}

local ai_keymap = '<leader>ccc'

return function()
  require('copilot').setup {
    copilot_node_command = 'node',
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

  require('mcphub').setup {
    extensions = {
      avante = { enabled = true, make_slash_commands = true },
      copilotchat = {
        enabled = false,
        convert_tools_to_functions = true,
        convert_resources_to_functions = true,
        add_mcp_prefix = true,
      },
    },
  }

  require('agentic').setup {
    provider = 'cursor-acp',
    keymaps = { prompt = { paste_image = { { '<localleader>p', mode = { 'n' } } } } },
  }

  vim.keymap.set({ 'n', 'v', 'i' }, ai_keymap, function()
    require('agentic').toggle()
  end, { desc = 'Toggle Agentic Chat' })
  vim.keymap.set({ 'n', 'v' }, "<C-'>", function()
    require('agentic').add_selection_or_file_to_context()
  end, { desc = 'Add file or selection to Agentic to Context' })
  vim.keymap.set({ 'n', 'v', 'i' }, '<C-,>', function()
    require('agentic').new_session()
  end, { desc = 'New Agentic Session' })
end
