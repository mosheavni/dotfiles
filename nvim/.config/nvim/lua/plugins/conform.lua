local function notify_format(err, did_format)
  if err then
    vim.notify('Error formatting: ' .. err)
    return
  end
  if did_format then
    vim.notify 'Formatted'
  end
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
        require('conform').format({ async = true }, notify_format)
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
      return { timeout_ms = 5000 }, notify_format
    end,
    -- Customize formatters
    formatters = {},
  },
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
