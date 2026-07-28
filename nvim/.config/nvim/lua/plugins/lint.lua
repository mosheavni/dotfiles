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
  ---@field enabled? boolean
  ---@field events? vim.api.keyset.events[]
  ---@field root_markers? string[]

  ---@type table<string, LinterConfig>
  -- Event triggers distinguish global linters from filetype-only linter configuration.
  local linters = {
    codespell = { enabled = true, events = { 'BufReadPost', 'BufWritePost' } },
    gitleaks = { enabled = true, events = { 'BufWritePost' } },
    luacheck = { root_markers = { '.luacheckrc' } },
    selene = { root_markers = { 'selene.toml' } },
    trivy = { enabled = false, events = { 'BufWritePost' } },
  }
  local excluded_filetypes = { 'gitcommit', 'gitrebase', 'fugitive' }

  lint.linters.brew_bundle = brew_bundle.linter

  lint.linters_by_ft = {
    Jenkinsfile = { 'npm-groovy-lint' },
    brewfile = { 'brew_bundle' },
    ['docker-compose'] = { 'dclint' },
    dockerfile = { 'hadolint' },
    ghaction = { 'actionlint' },
    groovy = { 'npm-groovy-lint' },
    python = { 'ruff' },
    lua = { 'selene', 'luacheck' },
    make = { 'checkmake' },
    markdown = { 'markdownlint' },
    toml = { 'tombi' },
    vim = { 'vint' },
    zsh = { 'zsh' },
  }

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
    local config = linters[linter_name]
    local markers = config and config.root_markers
    if markers then
      return find_root(markers, bufnr)
    end
    return nil
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

  ---Build lint targets that apply to a buffer and autocmd event.
  ---@param bufnr integer
  ---@param event vim.api.keyset.events
  ---@return LintTarget[]
  local function lint_targets(bufnr, event)
    local buffer_linter_names = lint._resolve_linter_by_ft(vim.bo[bufnr].filetype)
    -- The registry also contains filetype-only configuration, so eligibility retains
    -- whether each candidate came from the buffer's resolved linter list.
    local candidate_linter_names = vim.list_extend(vim.deepcopy(buffer_linter_names), vim.tbl_keys(linters))

    return vim
      .iter(candidate_linter_names)
      :unique()
      :filter(function(linter_name)
        local config = linters[linter_name]
        local event_matches = config ~= nil and config.events ~= nil and vim.tbl_contains(config.events, event)
        -- Filetype-selected linters run on every lint event; other registry entries
        -- must explicitly opt into the current event.
        return is_linter_enabled(linter_name) and (vim.tbl_contains(buffer_linter_names, linter_name) or event_matches)
      end)
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
