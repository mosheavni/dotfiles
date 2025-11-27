local treesitter_plugin = {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  event = 'BufReadPost',
  config = function()
    require('nvim-treesitter').setup { install_dir = vim.fn.stdpath 'data' .. '/treesitter' }
    require('nvim-treesitter').install {
      'awk',
      'bash',
      'comment',
      'csv',
      'diff',
      'dockerfile',
      'embedded_template',
      'git_config',
      'gitcommit',
      'gitignore',
      'go',
      'gomod',
      'gosum',
      'gotmpl',
      'gowork',
      'graphql',
      'groovy',
      'hcl',
      'helm',
      'hjson',
      'html',
      'http',
      'java',
      'javascript',
      'json',
      'jsonc',
      'lua',
      'luadoc',
      'make',
      'markdown',
      'markdown_inline',
      'python',
      'query',
      'regex',
      'scss',
      'sql',
      'ssh_config',
      'terraform',
      'toml',
      'tsx',
      'typescript',
      'vim',
      'vimdoc',
      'xml',
      'yaml',
    }

    vim.treesitter.language.register('markdown', 'octo')

    local augroup = vim.api.nvim_create_augroup('myconfig.treesitter', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      group = augroup,
      pattern = { '*' },
      callback = function(event)
        local filetype = event.match
        local lang = vim.treesitter.language.get_lang(filetype)
        if not lang then
          return
        end

        local is_installed, _ = vim.treesitter.language.add(lang)

        if not is_installed then
          local available_langs = require('nvim-treesitter').get_available()
          local is_available = vim.tbl_contains(available_langs, lang)

          if is_available then
            vim.notify('Parser available for ' .. lang .. '. Please add to install func', vim.log.levels.INFO)
            return
          end
        end

        local ok, _ = pcall(vim.treesitter.start, event.buf)
        if not ok then
          return
        end

        vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

        vim.wo.foldmethod = 'expr'
        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      end,
    })
  end,
}

return {
  treesitter_plugin,
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    event = 'BufReadPost',
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = 'BufReadPost',
    opts = {},
  },
  {
    'folke/ts-comments.nvim',
    event = 'BufReadPost',
    opts = {},
  },
  {
    'windwp/nvim-ts-autotag',
    ft = { 'html', 'javascript', 'jsx', 'markdown', 'typescript', 'xml', 'markdown' },
    opts = {},
  },
}
