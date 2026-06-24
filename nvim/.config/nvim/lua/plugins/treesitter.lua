vim.pack.add {
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
  'https://github.com/folke/ts-comments.nvim',
}

return function()
  vim.treesitter.language.register('ruby', 'brewfile')

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('myconfig.treesitter', { clear = true }),
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

      if not vim.treesitter.query.get(lang, 'highlights') then
        return
      end

      if not pcall(vim.treesitter.start, event.buf) then
        return
      end

      vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      local win = vim.api.nvim_get_current_win()
      if not vim.wo[win].diff then
        vim.wo[win][0].foldmethod = 'expr'
        vim.wo[win][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      end
    end,
  })

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
    'json5',
    'latex',
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
    'ruby',
    'rust',
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

  require('treesitter-context').setup {}
  require('ts-comments').setup {}
end
