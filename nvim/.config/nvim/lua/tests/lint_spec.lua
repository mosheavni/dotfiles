---@diagnostic disable: undefined-field
local eq = assert.are.same

describe('lint plugin', function()
  local lint
  local original_pack_add
  local original_brew_bundle
  local original_menu
  local original_buf_name
  local test_dir

  before_each(function()
    original_pack_add = vim.pack.add
    original_brew_bundle = package.loaded['user.lint.brew_bundle']
    original_menu = package.loaded['user.menu']
    original_buf_name = vim.api.nvim_buf_get_name(0)

    vim.pack.add = function() end
    lint = {
      linters = {
        actionlint = {},
        luacheck = {},
      },
      try_lint = function(name, opts)
        lint.last_lint = { name = name, opts = opts }
        table.insert(lint.calls, lint.last_lint)
      end,
      _resolve_linter_by_ft = function(filetype)
        if filetype == 'lua' then
          return { 'selene', 'luacheck' }
        end
        return filetype == 'python' and { 'ruff' } or {}
      end,
    }
    lint.calls = {}
    package.loaded.lint = lint
    package.loaded['user.lint.brew_bundle'] = { linter = {} }
    package.loaded['user.menu'] = { add_actions = function() end }
    vim.bo.filetype = 'lua'

    dofile 'lua/plugins/lint.lua'()
  end)

  after_each(function()
    vim.api.nvim_buf_set_name(0, original_buf_name)
    if test_dir then
      vim.fn.delete(test_dir, 'rf')
    end
    pcall(vim.api.nvim_del_user_command, 'LintToggle')
    pcall(vim.api.nvim_del_user_command, 'LintInfo')
    vim.api.nvim_del_augroup_by_name 'nvim-lint'
    vim.pack.add = original_pack_add
    package.loaded.lint = nil
    package.loaded['user.lint.brew_bundle'] = original_brew_bundle
    package.loaded['user.menu'] = original_menu
  end)

  it('completes linters configured for the current buffer and global linters', function()
    eq(vim.fn.getcompletion('LintToggle ', 'cmdline'), { 'codespell', 'gitleaks', 'luacheck', 'selene', 'trivy' })
  end)

  it('toggles a buffer linter and runs it when enabled', function()
    vim.cmd 'LintToggle luacheck'
    vim.cmd 'LintToggle luacheck'

    eq(lint.last_lint.name, 'luacheck')
    eq(lint.last_lint.opts.cwd, nil)
  end)

  it('does not add filetype linters to global completion', function()
    vim.cmd 'LintToggle luacheck'
    vim.bo.filetype = 'python'

    eq(vim.fn.getcompletion('LintToggle ', 'cmdline'), { 'codespell', 'gitleaks', 'ruff', 'trivy' })
  end)

  it('lists enabled and disabled linters', function()
    vim.cmd 'LintToggle luacheck'

    local output
    local original_print = print
    _G.print = function(message)
      output = message
    end
    vim.cmd 'LintInfo'
    _G.print = original_print

    eq(
      output,
      table.concat({
        'filetype (lua): selene',
        'filetype disabled: luacheck',
        'global: codespell, gitleaks',
        'global disabled: trivy',
      }, '\n')
    )
  end)

  it('enables a globally disabled linter', function()
    vim.cmd 'LintToggle trivy'

    eq(lint.last_lint.name, 'trivy')
  end)

  it('runs enabled global linters on their configured events', function()
    vim.api.nvim_exec_autocmds('BufReadPost', { buffer = 0, modeline = false })

    eq(lint.calls, {
      { name = 'selene', opts = { cwd = nil } },
      { name = 'luacheck', opts = { cwd = nil } },
      { name = 'codespell', opts = { cwd = nil } },
    })

    lint.calls = {}
    vim.api.nvim_exec_autocmds('BufWritePost', { buffer = 0, modeline = false })

    local linter_names = {}
    for _, call in ipairs(lint.calls) do
      table.insert(linter_names, call.name)
    end
    table.sort(linter_names)
    eq(linter_names, { 'codespell', 'gitleaks', 'luacheck', 'selene' })
  end)

  it('does not run configured linters outside their buffer filetype', function()
    vim.bo.filetype = 'python'
    lint.calls = {}

    vim.api.nvim_exec_autocmds('InsertLeave', { buffer = 0, modeline = false })

    eq(lint.calls, { { name = 'ruff', opts = { cwd = nil } } })
  end)

  it('uses the configured root marker as the linter cwd', function()
    test_dir = vim.fn.tempname()
    vim.fn.mkdir(test_dir, 'p')
    vim.fn.writefile({}, test_dir .. '/.luacheckrc')
    vim.api.nvim_buf_set_name(0, test_dir .. '/example.lua')
    lint.calls = {}

    vim.api.nvim_exec_autocmds('InsertLeave', { buffer = 0, modeline = false })

    for _, call in ipairs(lint.calls) do
      if call.name == 'luacheck' then
        eq(call.opts.cwd, test_dir)
        return
      end
    end
    error 'luacheck was not run'
  end)
end)
