local function notify_format(err, did_format)
  if err then
    vim.notify('Error formatting: ' .. err)
    return
  end
  if did_format then
    vim.notify 'Formatted'
  end
end

local function get_lsp_formatters(bufnr)
  local method = 'textDocument/formatting'
  local clients = vim.tbl_values(vim.lsp.get_clients { bufnr = bufnr })
  local formatting_clients = {}
  for _, client in ipairs(clients) do
    if client.supports_method(method) then
      table.insert(formatting_clients, { name = client.name, type = 'lsp' })
    end
  end
  return formatting_clients
end

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      -- Customize or remove this keymap to your liking
      '<leader>lp',
      function()
        local conform_fmts = require('conform').list_formatters()
        local lsp_fmts = get_lsp_formatters(vim.api.nvim_get_current_buf())
        local merged = vim.list_extend(lsp_fmts, conform_fmts)
        return vim.ui.select(merged, {
          prompt = 'Select LSP client',
          format_item = function(client)
            return client.name
          end,
        }, function(client)
          if client == nil then
            return
          end
          local conform_opts = {
            callback = notify_format,
            formatters = { client.name },
            stop_after_first = true,
          }
          if client.type and client.type == 'lsp' then
            conform_opts = { formatters = {}, lsp_format = 'prefer' }
          end
          require('conform').format(conform_opts)
        end)
      end,
      mode = '',
      desc = 'Format buffer',
    },
  },
  -- This will provide type hinting with LuaLS
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    log_level = vim.log.levels.DEBUG,
    -- Define your formatters
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'isort', 'black' },
      markdown = { 'injected', 'markdownlint' },
      terraform = { 'terraform_fmt' },
      hcl = { 'terragrunt_hclfmt' },
      xml = { 'xmllint' },
      sh = { 'shfmt' },

      groovy = { 'npm-groovy-lint' },
      Jenkinsfile = { 'npm-groovy-lint' },

      -- prettierd
      javascript = { 'prettierd' },
      javascriptreact = { 'prettierd' },
      typescript = { 'prettierd' },
      typescriptreact = { 'prettierd' },
      vue = { 'prettierd' },
      css = { 'prettierd' },
      scss = { 'prettierd' },
      less = { 'prettierd' },
      html = { 'prettierd' },
      json = { 'prettierd' },
      jsonc = { 'prettierd' },
      yaml = { 'prettierd' },
      ['markdown.mdx'] = { 'prettierd' },
      graphql = { 'prettierd' },
      handlebars = { 'prettierd' },
      svelte = { 'prettierd' },
      astro = { 'prettierd' },
      htmlangular = { 'prettierd' },
    },
    -- Set default options
    default_format_opts = {
      lsp_format = 'fallback',
    },
    -- Set up format-on-save
    format_on_save = function()
      ---@diagnostic disable-next-line: redundant-return-value
      return {
        lsp_format = 'fallback',
        timeout_ms = 5000,
        ---@diagnostic disable-next-line: redundant-return-value
      },
        notify_format
    end,
    -- Customize formatters
    formatters = {},
  },
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
