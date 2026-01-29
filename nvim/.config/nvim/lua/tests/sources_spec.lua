---@diagnostic disable: undefined-field, need-check-nil
--# selene: allow(undefined_variable)
local sources = require 'user.sources'
local eq = assert.are.same

describe('user.sources', function()
  describe('is_linter_enabled', function()
    before_each(function()
      -- Reset state by clearing the module and reloading
      package.loaded['user.sources'] = nil
      package.loaded['lint'] = {
        linters_by_ft = { lua = { 'selene', 'luacheck' } },
        _disabled_linters = {},
        _global_linter_names = {},
      }
      sources = require 'user.sources'
    end)

    it('returns true for linters not in disabled state', function()
      assert.is_true(sources.is_linter_enabled 'selene')
      assert.is_true(sources.is_linter_enabled 'luacheck')
    end)

    it('returns false after disabling a linter', function()
      sources.toggle_linter 'selene'
      assert.is_false(sources.is_linter_enabled 'selene')
      assert.is_true(sources.is_linter_enabled 'luacheck')
    end)

    it('returns true after re-enabling a linter', function()
      sources.toggle_linter 'selene'
      assert.is_false(sources.is_linter_enabled 'selene')

      sources.toggle_linter 'selene'
      assert.is_true(sources.is_linter_enabled 'selene')
    end)
  end)

  describe('is_formatter_enabled', function()
    before_each(function()
      package.loaded['user.sources'] = nil
      package.loaded['conform'] = {
        formatters_by_ft = { lua = { 'stylua' } },
      }
      sources = require 'user.sources'
    end)

    it('returns true for formatters not in disabled state', function()
      assert.is_true(sources.is_formatter_enabled('stylua', 'lua'))
      assert.is_true(sources.is_formatter_enabled('prettierd', 'javascript'))
    end)

    it('returns false after disabling a formatter', function()
      sources.toggle_formatter('stylua', 'lua')
      assert.is_false(sources.is_formatter_enabled('stylua', 'lua'))
    end)

    it('returns true after re-enabling a formatter', function()
      sources.toggle_formatter('stylua', 'lua')
      assert.is_false(sources.is_formatter_enabled('stylua', 'lua'))

      sources.toggle_formatter('stylua', 'lua')
      assert.is_true(sources.is_formatter_enabled('stylua', 'lua'))
    end)
  end)

  describe('toggle_linter', function()
    before_each(function()
      package.loaded['user.sources'] = nil
      package.loaded['lint'] = {
        linters_by_ft = { lua = { 'selene', 'luacheck' } },
        _disabled_linters = {},
        _global_linter_names = { 'codespell' },
      }
      sources = require 'user.sources'
    end)

    it('sets _disabled_linters when disabling', function()
      local lint = require 'lint'
      eq(lint._disabled_linters['selene'], nil)

      sources.toggle_linter 'selene'
      eq(lint._disabled_linters['selene'], true)
    end)

    it('clears _disabled_linters when enabling', function()
      local lint = require 'lint'

      sources.toggle_linter 'selene'
      eq(lint._disabled_linters['selene'], true)

      sources.toggle_linter 'selene'
      eq(lint._disabled_linters['selene'], nil)
    end)

    it('returns new state after toggle', function()
      eq(sources.toggle_linter 'selene', false)
      eq(sources.toggle_linter 'selene', true)
    end)

    it('works with global linters', function()
      eq(sources.toggle_linter 'codespell', false)
      assert.is_false(sources.is_linter_enabled 'codespell')

      eq(sources.toggle_linter 'codespell', true)
      assert.is_true(sources.is_linter_enabled 'codespell')
    end)
  end)

  describe('toggle_formatter', function()
    before_each(function()
      package.loaded['user.sources'] = nil
      package.loaded['conform'] = {
        formatters_by_ft = { lua = { 'stylua' }, javascript = { 'prettierd', 'eslint_d' } },
      }
      sources = require 'user.sources'
    end)

    it('removes formatter from formatters_by_ft when disabling', function()
      local conform = require 'conform'
      eq(conform.formatters_by_ft.lua, { 'stylua' })

      sources.toggle_formatter('stylua', 'lua')
      eq(conform.formatters_by_ft.lua, {})
    end)

    it('adds formatter back to formatters_by_ft when enabling', function()
      local conform = require 'conform'

      sources.toggle_formatter('stylua', 'lua')
      eq(conform.formatters_by_ft.lua, {})

      sources.toggle_formatter('stylua', 'lua')
      eq(conform.formatters_by_ft.lua, { 'stylua' })
    end)

    it('returns new state after toggle', function()
      eq(sources.toggle_formatter('stylua', 'lua'), false)
      eq(sources.toggle_formatter('stylua', 'lua'), true)
    end)

    it('handles multiple formatters correctly', function()
      local conform = require 'conform'

      sources.toggle_formatter('prettierd', 'javascript')
      eq(conform.formatters_by_ft.javascript, { 'eslint_d' })

      sources.toggle_formatter('eslint_d', 'javascript')
      eq(conform.formatters_by_ft.javascript, {})

      sources.toggle_formatter('prettierd', 'javascript')
      eq(conform.formatters_by_ft.javascript, { 'prettierd' })
    end)
  end)

  describe('build_content', function()
    before_each(function()
      package.loaded['user.sources'] = nil
      sources = require 'user.sources'
    end)

    it('returns lines and mappings arrays of same length', function()
      -- Create a test buffer
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_option_value('filetype', 'lua', { buf = buf })

      -- Mock dependencies to return empty
      package.loaded['lint'] = { linters_by_ft = {}, _disabled_linters = {}, _global_linter_names = {} }
      package.loaded['conform'] = { formatters_by_ft = {} }

      local lines, mappings = sources.build_content(buf)

      eq(#lines, #mappings)
      assert.is_true(#lines > 0)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('includes hints line as first line', function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_option_value('filetype', 'lua', { buf = buf })

      package.loaded['lint'] = { linters_by_ft = {}, _disabled_linters = {}, _global_linter_names = {} }
      package.loaded['conform'] = { formatters_by_ft = {} }

      local lines, mappings = sources.build_content(buf)

      assert.is_true(lines[1]:find '<Tab>' ~= nil)
      eq(mappings[1].line_type, 'hints')

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('includes section headers', function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_option_value('filetype', 'lua', { buf = buf })

      package.loaded['lint'] = { linters_by_ft = {}, _disabled_linters = {}, _global_linter_names = {} }
      package.loaded['conform'] = { formatters_by_ft = {} }

      local lines, _ = sources.build_content(buf)

      local has_lsp_header = false
      local has_linter_header = false
      local has_formatter_header = false

      for _, line in ipairs(lines) do
        if line == 'LSPs:' then
          has_lsp_header = true
        end
        if line == 'Linters:' then
          has_linter_header = true
        end
        if line == 'Formatters:' then
          has_formatter_header = true
        end
      end

      assert.is_true(has_lsp_header)
      assert.is_true(has_linter_header)
      assert.is_true(has_formatter_header)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('includes linters for filetype', function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_option_value('filetype', 'lua', { buf = buf })

      package.loaded['lint'] = {
        linters_by_ft = { lua = { 'selene', 'luacheck' } },
        _disabled_linters = {},
        _global_linter_names = {},
      }
      package.loaded['conform'] = { formatters_by_ft = {} }

      local lines, mappings = sources.build_content(buf)

      local found_selene = false
      local found_luacheck = false

      for i, line in ipairs(lines) do
        if line:find 'selene' then
          found_selene = true
          eq(mappings[i].item.type, 'linter')
          eq(mappings[i].item.name, 'selene')
        end
        if line:find 'luacheck' then
          found_luacheck = true
          eq(mappings[i].item.type, 'linter')
          eq(mappings[i].item.name, 'luacheck')
        end
      end

      assert.is_true(found_selene)
      assert.is_true(found_luacheck)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('includes global linters', function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_option_value('filetype', 'lua', { buf = buf })

      package.loaded['lint'] = {
        linters_by_ft = {},
        _disabled_linters = {},
        _global_linter_names = { 'codespell', 'gitleaks' },
      }
      package.loaded['conform'] = { formatters_by_ft = {} }

      local lines, mappings = sources.build_content(buf)

      local found_codespell = false
      local found_gitleaks = false

      for i, line in ipairs(lines) do
        if line:find 'codespell' then
          found_codespell = true
          eq(mappings[i].item.type, 'linter')
          eq(mappings[i].item.name, 'codespell')
        end
        if line:find 'gitleaks' then
          found_gitleaks = true
          eq(mappings[i].item.type, 'linter')
          eq(mappings[i].item.name, 'gitleaks')
        end
      end

      assert.is_true(found_codespell)
      assert.is_true(found_gitleaks)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('includes formatters for filetype', function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_option_value('filetype', 'lua', { buf = buf })

      package.loaded['lint'] = { linters_by_ft = {}, _disabled_linters = {}, _global_linter_names = {} }
      package.loaded['conform'] = { formatters_by_ft = { lua = { 'stylua' } } }

      local lines, mappings = sources.build_content(buf)

      local found_stylua = false

      for i, line in ipairs(lines) do
        if line:find 'stylua' then
          found_stylua = true
          eq(mappings[i].item.type, 'formatter')
          eq(mappings[i].item.name, 'stylua')
        end
      end

      assert.is_true(found_stylua)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe('get_item_at_cursor', function()
    it('returns nil for non-item lines', function()
      local mappings = {
        { line_type = 'hints' },
        { line_type = 'empty' },
        { line_type = 'header' },
      }

      assert.is_nil(sources.get_item_at_cursor(mappings, 1))
      assert.is_nil(sources.get_item_at_cursor(mappings, 2))
      assert.is_nil(sources.get_item_at_cursor(mappings, 3))
    end)

    it('returns item for item lines', function()
      local test_item = { type = 'linter', name = 'selene', enabled = true }
      local mappings = {
        { line_type = 'hints' },
        { line_type = 'header' },
        { line_type = 'item', item = test_item },
      }

      local result = sources.get_item_at_cursor(mappings, 3)
      assert.is_not_nil(result)
      eq(result.type, 'linter')
      eq(result.name, 'selene')
      eq(result.enabled, true)
    end)

    it('returns nil for out of bounds cursor', function()
      local mappings = {
        { line_type = 'hints' },
      }

      assert.is_nil(sources.get_item_at_cursor(mappings, 0))
      assert.is_nil(sources.get_item_at_cursor(mappings, 5))
    end)
  end)
end)
