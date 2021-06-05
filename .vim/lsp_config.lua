lspconfig = require'lspconfig'
completion_callback = require'completion'.on_attach

-- language servers
lspconfig.pyls.setup{}
lspconfig.tsserver.setup{}

-- completion
lspconfig.pyls.setup{on_attach=completion_callback}
lspconfig.tsserver.setup{on_attach=completion_callback}
lspconfig.rust_analyzer.setup{on_attach=completion_callback}
