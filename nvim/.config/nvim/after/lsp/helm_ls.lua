-- Get yaml config (may trigger yamlls.lua to load and cache it)
local yaml_cfg = _G.yaml_lsp_config or dofile(vim.fn.stdpath 'config' .. '/after/lsp/yamlls.lua')

return {
  filetypes = { 'helm', 'gotmpl' },
  settings = {
    yamlls = {
      config = yaml_cfg.settings,
    },
  },
}
