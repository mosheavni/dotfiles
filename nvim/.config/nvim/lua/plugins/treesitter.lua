local treesitter_plugin = {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  build = ':TSUpdate',
  event = { 'BufReadPost', 'FileType' },
  init = function()
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
          if vim.tbl_contains(available_langs, lang) then
            vim.notify('Parser available for ' .. lang .. '. Please add to install func', vim.log.levels.INFO)
          end
          return
        end

        if not pcall(vim.treesitter.start, event.buf) then
          return
        end

        vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

        vim.wo[0][0].foldmethod = 'expr'
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      end,
    })
  end,

  config = function()
    require('nvim-treesitter').setup { install_dir = vim.fn.stdpath 'data' .. '/treesitter' }
    require('nvim-treesitter').install {
      'awk',
      'bash',
      'comment',
      'css',
      'csv',
      'diff',
      'dockerfile',
      'editorconfig',
      'embedded_template',
      'git_config',
      'git_rebase',
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
      'ini',
      'java',
      'javascript',
      'jinja',
      'jinja_inline',
      'jq',
      'json',
      'jsonc',
      'lua',
      'luadoc',
      'luap',
      'make',
      'markdown',
      'markdown_inline',
      'passwd',
      'pem',
      'printf',
      'python',
      'query',
      'regex',
      'requirements',
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
      'zsh',
    }
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
    ft = { 'html', 'javascript', 'jsx', 'markdown', 'typescript', 'xml' },
    opts = {},
  },
}
