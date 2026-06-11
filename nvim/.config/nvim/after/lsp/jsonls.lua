vim.pack.add { 'https://github.com/b0o/SchemaStore.nvim' }

return {
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
