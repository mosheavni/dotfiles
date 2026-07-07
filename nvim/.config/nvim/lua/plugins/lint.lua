vim.pack.add { 'https://github.com/mfussenegger/nvim-lint' }

local function find_root(markers, bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local root = vim.fs.find(markers, { path = path, upward = true })[1]
  return root and vim.fs.dirname(root) or nil
end

return function()
  local lint = require 'lint'
  local brew_bundle = require 'user.lint.brew_bundle'

  local disabled_linters = { trivy = true }

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

  local linter_root_markers = {
    selene = { 'selene.toml' },
    luacheck = { '.luacheckrc' },
  }

  local function get_linter_cwd(linter_name, bufnr)
    local markers = linter_root_markers[linter_name]
    if markers then
      return find_root(markers, bufnr)
    end
    return nil
  end

  local group = vim.api.nvim_create_augroup('nvim-lint', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
    group = group,
    callback = function(args)
      local excluded_filetypes = { 'gitcommit', 'gitrebase', 'fugitive' }
      if vim.tbl_contains(excluded_filetypes, vim.bo[args.buf].filetype) or not vim.bo[args.buf].modifiable then
        return
      end
      if vim.api.nvim_buf_get_name(args.buf):match '^%w+://' then
        return
      end

      local linters = lint._resolve_linter_by_ft(vim.bo[args.buf].filetype)
      for _, linter_name in ipairs(linters) do
        if not disabled_linters[linter_name] then
          lint.try_lint(linter_name, { cwd = get_linter_cwd(linter_name, args.buf) })
        end
      end

      if args.event == 'BufWritePost' then
        if not disabled_linters.gitleaks then
          lint.try_lint { 'gitleaks' }
        end
        if not disabled_linters.trivy then
          lint.try_lint { 'trivy' }
        end
      end

      if args.event == 'BufReadPost' or args.event == 'BufWritePost' then
        if not disabled_linters.codespell then
          lint.try_lint { 'codespell' }
        end
      end
    end,
  })

  vim.api.nvim_create_user_command('TrivyLintToggle', function()
    disabled_linters.trivy = not disabled_linters.trivy
    local status = disabled_linters.trivy and 'disabled' or 'enabled'
    print('Trivy linting ' .. status)
    if not disabled_linters.trivy then
      lint.try_lint { 'trivy' }
    else
      vim.diagnostic.reset(vim.api.nvim_create_namespace 'trivy', 0)
    end
  end, {})

  require('user.menu').add_actions('Lint', {
    ['Toggle Trivy linting (:TrivyLintToggle)'] = function()
      vim.cmd [[TrivyLintToggle]]
    end,
  })
end
