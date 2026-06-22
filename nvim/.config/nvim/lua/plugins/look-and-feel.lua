vim.pack.add {
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/luukvbaal/statuscol.nvim',
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  'https://github.com/kevinhwang91/nvim-bqf',
}

return function()
  require('nvim-web-devicons').setup {
    override_by_extension = {
      hcl = {
        icon = '',
        color = '#7182D0',
        name = 'HCL',
      },
    },
  }
  require('nvim-web-devicons').set_icon_by_filetype { fugitive = 'git' }

  local builtin = require 'statuscol.builtin'
  require('statuscol').setup {
    relculright = true,
    segments = {
      { text = { builtin.foldfunc }, click = 'v:lua.ScFa' },
      { text = { '%s' }, click = 'v:lua.ScSa' },
      {
        text = { builtin.lnumfunc, ' ' },
        condition = { true, builtin.not_empty },
        click = 'v:lua.ScLa',
      },
    },
  }

  require('render-markdown').setup {
    file_types = { 'markdown', 'Avante', 'AgenticChat' },
  }

  require('bqf').setup {
    func_map = {
      prevhist = '<',
      nexthist = '>',
    },
  }
end
