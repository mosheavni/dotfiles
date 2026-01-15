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
