vim.pack.add { 'https://github.com/stevearc/conform.nvim' }

local function get_lsp_formatters(bufnr)
  local formatting_clients = {}
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    ---@diagnostic disable-next-line: param-type-mismatch
    if client:supports_method('textDocument/formatting', bufnr) then
      table.insert(formatting_clients, { name = client.name, type = 'lsp' })
    end
  end
  return formatting_clients
end

local function get_formatter_names(bufnr)
  local fmts, is_lsp = require('conform').list_formatters_to_run(bufnr)
  local list = is_lsp and get_lsp_formatters(bufnr) or fmts
  -- stylua: ignore
  return table.concat(vim.tbl_map(function(f) return f.name end, list), ', ')
end

return function()
  vim.o.formatexpr = "v:lua.require'conform'.formatexpr({lsp_format='fallback',timeout_ms=5000})"

  require('conform').setup {
    log_level = vim.log.levels.INFO,
    formatters_by_ft = {
      Jenkinsfile = { 'npm-groovy-lint' },
      astro = { 'prettierd' },
      css = { 'prettierd' },
      graphql = { 'prettierd' },
      groovy = { 'npm-groovy-lint' },
      handlebars = { 'prettierd' },
      hcl = { 'terragrunt_hclfmt' },
      html = { 'prettierd' },
      htmlangular = { 'prettierd' },
      javascript = { 'prettierd' },
      javascriptreact = { 'prettierd' },
      json = { 'prettierd' },
      jsonc = { 'prettierd' },
      less = { 'prettierd' },
      lua = { 'stylua' },
      markdown = { 'prettier', 'cbfmt', 'injected', 'markdownlint' },
      python = function(bufnr)
        if require('conform').get_formatter_info('ruff_format', bufnr).available then
          return { 'isort', 'ruff_format' }
        end
        return { 'isort', 'black' }
      end,
      scss = { 'prettierd' },
      sh = { 'shfmt' },
      svelte = { 'prettierd' },
      terraform = { 'terraform_fmt' },
      toml = { 'tombi' },
      typescript = { 'prettierd' },
      typescriptreact = { 'prettierd' },
      vue = { 'prettierd' },
      xml = { 'xmllint' },
      yaml = { 'prettierd' },
      zsh = { 'shfmt' },
    },
    default_format_opts = { lsp_format = 'fallback' },
    format_on_save = function(bufnr)
      vim.b[bufnr].format_changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
      return { lsp_format = 'fallback', timeout_ms = 5000 }
    end,
    format_after_save = function(bufnr)
      local old_changedtick = vim.b[bufnr].format_changedtick
      local new_changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
      if old_changedtick and new_changedtick > old_changedtick then
        local formatter_names = get_formatter_names(bufnr)
        if formatter_names ~= '' then
          vim.notify(string.format('Formatted using %s', formatter_names))
        end
      end
      vim.b[bufnr].format_changedtick = nil
    end,
    formatters = {},
  }

  vim.keymap.set('n', '<leader>lp', function()
    local conform_fmts = require('conform').list_formatters()
    local lsp_fmts = get_lsp_formatters(vim.api.nvim_get_current_buf())
    vim.ui.select(vim.list_extend(lsp_fmts, conform_fmts), {
      prompt = 'Select formatter❯ ',
      title = 'Formatters',
      -- stylua: ignore
      format_item = function(client) return client.name end,
    }, function(client)
      -- stylua: ignore
      if not client then return end
      local conform_opts = { formatters = { client.name }, stop_after_first = true }
      if client.type == 'lsp' then
        conform_opts = { formatters = {}, lsp_format = 'prefer' }
      end
      require('conform').format(conform_opts, function(err, did_format)
        if did_format then
          vim.notify(err and ('Error formatting: ' .. err) or ('Formatted using ' .. client.name))
        end
      end)
    end)
  end, { desc = 'Format buffer' })
end
