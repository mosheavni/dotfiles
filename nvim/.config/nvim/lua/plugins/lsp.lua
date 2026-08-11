vim.pack.add {
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/j-hui/fidget.nvim',
  'https://github.com/folke/lazydev.nvim',
  'https://github.com/DrKJeff16/wezterm-types',
}

return function()
  require('user.lsp.config').setup()

  require('fidget').setup {
    progress = {
      display = {
        progress_icon = { pattern = 'moon', period = 1 },
      },
    },
  }

  vim.keymap.set('n', '<leader>cs', function()
    require('yaml-companion').open_ui_select()
  end, { remap = false, silent = true })
  vim.api.nvim_create_user_command('YamlYankKey', function()
    local info = require('yaml-companion').get_key_at_cursor()
    if info and info.key then
      vim.fn.setreg('+', info.key)
      vim.notify('Copied: ' .. info.key)
    end
  end, {})
  require('user.menu').add_actions('YAML', {
    ['Change Schema'] = function()
      require('yaml-companion').open_ui_select()
    end,
    ['Copy Yaml Key at Cursor to clipboard (:YamlYankKey)'] = function()
      vim.cmd [[YamlYankKey]]
    end,
  })

  require('lazydev').setup {
    library = {
      { path = 'wezterm-types', mods = { 'wezterm' } },
      { path = 'plenary.nvim', words = { 'describe', 'assert' } },
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      { path = '${3rd}/busted/library', words = { 'describe', 'it', 'assert' } },
      { path = '${3rd}/luassert/library', words = { 'assert' } },
    },
  }
end
