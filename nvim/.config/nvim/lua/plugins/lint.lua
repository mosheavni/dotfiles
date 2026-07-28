vim.pack.add { 'https://github.com/mfussenegger/nvim-lint' }

---Find the closest ancestor directory containing one of the given markers.
---@param markers string[]
---@param bufnr integer
---@return string|nil
local function find_root(markers, bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = vim.fs.find(markers, { path = path, upward = true })[1]
  return root and vim.fs.dirname(root) or nil
end

---Configure nvim-lint, its commands, and event-driven linting.
---@return nil
local function setup()
  local lint = require 'lint'
  local brew_bundle = require 'user.lint.brew_bundle'

  ---@class LinterConfig
  ---@field filetypes? string[] Filetypes this linter runs on; runs on every lint event.
  ---@field events? vim.api.keyset.events[] Events a global linter runs on, for every buffer.
  ---@field root_markers? string[] Files whose ancestor directory becomes the linter cwd.
  ---@field enabled? boolean

  ---@type table<string, LinterConfig>
  -- Single source of truth: `filetypes` declares filetype linters, `events` declares
  -- global linters that run on every buffer. `lint.linters_by_ft` is derived below.
  local linters = {
    ['npm-groovy-lint'] = { filetypes = { 'Jenkinsfile', 'groovy' } },
    brew_bundle = { filetypes = { 'brewfile' } },
    dclint = { filetypes = { 'docker-compose' } },
    hadolint = { filetypes = { 'dockerfile' } },
    actionlint = { filetypes = { 'ghaction' } },
    ruff = { filetypes = { 'python' } },
    selene = { filetypes = { 'lua' }, root_markers = { 'selene.toml' } },
    luacheck = { filetypes = { 'lua' }, root_markers = { '.luacheckrc' } },
    checkmake = { filetypes = { 'make' } },
    markdownlint = { filetypes = { 'markdown' } },
    tombi = { filetypes = { 'toml' } },
    vint = { filetypes = { 'vim' } },
    zsh = { filetypes = { 'zsh' } },

    -- global
    codespell = { events = { 'BufReadPost', 'BufWritePost' } },
    gitleaks = { events = { 'BufWritePost' } },
    trivy = { enabled = false, events = { 'BufWritePost' } },
  }
  local excluded_filetypes = { 'gitcommit', 'gitrebase', 'fugitive' }

  lint.linters.brew_bundle = brew_bundle.linter

  lint.linters_by_ft = {}
  for name, config in pairs(linters) do
    for _, ft in ipairs(config.filetypes or {}) do
      local ft_linters = lint.linters_by_ft[ft] or {}
      table.insert(ft_linters, name)
      lint.linters_by_ft[ft] = ft_linters
    end
  end

  lint.linters.actionlint.args = vim.list_extend({ '-ignore', 'label ".+" is unknown' }, lint.linters.actionlint.args or {})

  -- Luacheck reads stdin but still needs the buffer filename for config discovery.
  lint.linters.luacheck.args = {
    '--formatter',
    'plain',
    '--codes',
    '--ranges',
    '--filename',
    function()
      return vim.api.nvim_buf_get_name(0)
    end,
    '-',
  }

  ---Resolve the working directory required by a linter, if it declares root markers.
  ---@param linter_name string
  ---@param bufnr integer
  ---@return string|nil
  local function get_linter_cwd(linter_name, bufnr)
    local markers = linters[linter_name] and linters[linter_name].root_markers
    return markers and find_root(markers, bufnr) or nil
  end

  ---List global linters that declare one or more triggering events.
  ---@return string[]
  local function global_linter_names()
    return vim
      .iter(linters)
      -- Dictionary iterators provide both the linter name and its configuration.
      :filter(function(_, config)
        return config.events ~= nil
      end)
      :map(function(linter_name)
        return linter_name
      end)
      :totable()
  end

  ---List the buffer's filetype linters together with global linters.
  ---@param bufnr integer
  ---@return string[]
  local function available_linters(bufnr)
    local available = vim.deepcopy(lint._resolve_linter_by_ft(vim.bo[bufnr].filetype))
    -- Global linters are always toggleable, regardless of the current filetype.
    vim.list_extend(available, global_linter_names())
    table.sort(available)
    return vim.iter(available):unique():totable()
  end

  ---Return whether a linter is enabled in the local session.
  ---@param linter_name string
  ---@return boolean
  local function is_linter_enabled(linter_name)
    local config = linters[linter_name]
    return config == nil or config.enabled ~= false
  end

  ---Split linter names into sorted enabled and disabled lists.
  ---@param linter_names string[]
  ---@return string[] enabled
  ---@return string[] disabled
  local function partition_linters(linter_names)
    local enabled = vim.iter(linter_names):filter(is_linter_enabled):totable()
    local disabled = vim
      .iter(linter_names)
      :filter(function(linter_name)
        return not is_linter_enabled(linter_name)
      end)
      :totable()
    table.sort(enabled)
    table.sort(disabled)
    return enabled, disabled
  end

  ---@class LintTarget
  ---@field linter string
  ---@field opts table

  ---Build lint targets for a buffer and autocmd event: the buffer's filetype linters
  ---plus any global linters registered for the event, minus disabled ones.
  ---@param bufnr integer
  ---@param event vim.api.keyset.events
  ---@return LintTarget[]
  local function lint_targets(bufnr, event)
    local names = vim.deepcopy(lint._resolve_linter_by_ft(vim.bo[bufnr].filetype))
    for _, name in ipairs(global_linter_names()) do
      if vim.tbl_contains(linters[name].events, event) then
        table.insert(names, name)
      end
    end

    return vim
      .iter(names)
      :filter(is_linter_enabled)
      :map(function(linter_name)
        return { linter = linter_name, opts = { cwd = get_linter_cwd(linter_name, bufnr) } }
      end)
      :totable()
  end

  local group = vim.api.nvim_create_augroup('nvim-lint', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
    group = group,
    callback = function(args)
      -- Avoid linting special buffers that cannot be edited like normal files.
      if vim.tbl_contains(excluded_filetypes, vim.bo[args.buf].filetype) or not vim.bo[args.buf].modifiable then
        return
      end
      -- URI buffers are managed by plugins, not local filesystem linters.
      if vim.api.nvim_buf_get_name(args.buf):match '^%w+://' then
        return
      end

      for _, target in ipairs(lint_targets(args.buf, args.event)) do
        lint.try_lint(target.linter, target.opts)
      end
    end,
  })

  vim.api.nvim_create_user_command('LintToggle', function(args)
    local bufnr = vim.api.nvim_get_current_buf()
    local linter_name = args.args
    if not vim.tbl_contains(available_linters(bufnr), linter_name) then
      vim.notify(string.format('Linter %q is not available for this buffer', linter_name), vim.log.levels.ERROR)
      return
    end

    local enabled = not is_linter_enabled(linter_name)
    -- Filetype linters without explicit configuration keep their toggle state here.
    local config = linters[linter_name] or {}
    config.enabled = enabled
    linters[linter_name] = config

    local status = enabled and 'enabled' or 'disabled'
    print(string.format('%s linting %s', linter_name, status))
    if enabled then
      lint.try_lint(linter_name, { cwd = get_linter_cwd(linter_name, bufnr) })
    else
      -- Removing diagnostics prevents stale results after a linter is disabled.
      vim.diagnostic.reset(vim.api.nvim_create_namespace(linter_name), bufnr)
    end
  end, {
    nargs = 1,
    complete = function()
      return available_linters(0)
    end,
  })

  vim.api.nvim_create_user_command('LintInfo', function()
    local ft_linters, disabled_ft_linters = partition_linters(lint._resolve_linter_by_ft(vim.bo.filetype))
    local enabled_global_linters, disabled_global_linters = partition_linters(global_linter_names())

    local lines = {}
    table.insert(lines, string.format('filetype (%s): %s', vim.bo.filetype, #ft_linters > 0 and table.concat(ft_linters, ', ') or 'none'))
    table.insert(lines, string.format('filetype disabled: %s', #disabled_ft_linters > 0 and table.concat(disabled_ft_linters, ', ') or 'none'))
    table.insert(lines, string.format('global: %s', #enabled_global_linters > 0 and table.concat(enabled_global_linters, ', ') or 'none'))
    table.insert(lines, string.format('global disabled: %s', #disabled_global_linters > 0 and table.concat(disabled_global_linters, ', ') or 'none'))
    print(table.concat(lines, '\n'))
  end, {})
end

return setup
