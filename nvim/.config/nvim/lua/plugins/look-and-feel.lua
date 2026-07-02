vim.pack.add {
  'https://github.com/nvim-tree/nvim-web-devicons',
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

  require('render-markdown').setup {
    file_types = { 'markdown' },
  }

  require('bqf').setup {
    func_map = {
      prevhist = '<',
      nexthist = '>',
    },
  }
end
