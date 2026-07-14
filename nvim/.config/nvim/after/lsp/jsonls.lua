vim.pack.add { 'https://github.com/b0o/SchemaStore.nvim' }

return {
  filetypes = { 'json', 'jsonc', 'json.package' },
  settings = {
    json = {
      trace = {
        server = 'on',
      },
      schemas = require('schemastore').json.schemas(),
      validate = { enable = true },
    },
  },
}
