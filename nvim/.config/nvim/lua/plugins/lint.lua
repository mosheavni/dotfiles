-- Helper function to find root directory based on markers
local function find_root(markers)
  local path = vim.api.nvim_buf_get_name(0)
  local root = vim.fs.find(markers, {
    path = path,
    upward = true,
  })[1]
  return root and vim.fs.dirname(root) or nil
end

return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require 'lint'

    -- Trivy toggle state (disabled by default)
    local trivy_enabled = false

    lint.linters_by_ft = {
      -- hcl = { 'terragrunt_validate' },
      Jenkinsfile = { 'npm-groovy-lint' },
      ['docker-compose'] = { 'dclint' },
      dockerfile = { 'hadolint' },
      ghaction = { 'actionlint' },
      groovy = { 'npm-groovy-lint' },
      python = { 'ruff' },
      lua = { 'selene', 'luacheck' },
      make = { 'checkmake' },
      markdown = { 'proselint', 'write_good', 'markdownlint' },
      sh = { 'shellcheck' },
      toml = { 'tombi' },
      vim = { 'vint' },
      zsh = { 'zsh' },
    }

    -- Configure linter root markers (similar to LSP root_dir)
    local linter_root_markers = {
      selene = { 'selene.toml' },
    }

    -- Helper to get the appropriate cwd for a linter
    local function get_linter_cwd(linter_name)
      local markers = linter_root_markers[linter_name]
      if markers then
        return find_root(markers)
      end
      return nil
    end

    local group = vim.api.nvim_create_augroup('nvim-lint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave', 'TextChanged' }, {
      group = group,
      callback = function(args)
        local excluded_filetypes = { 'gitcommit', 'gitrebase', 'fugitive' }
        if vim.tbl_contains(excluded_filetypes, vim.bo.filetype) then
          return
        end

        if not vim.bo.modifiable then
          return
        end

        -- Get linters for current filetype
        local linters = lint._resolve_linter_by_ft(vim.bo.filetype)

        -- Run each linter with its configured cwd
        for _, linter_name in ipairs(linters) do
          local cwd = get_linter_cwd(linter_name)
          lint.try_lint(linter_name, { cwd = cwd })
        end

        -- Run gitleaks and trivy only on saved buffers (BufWritePost)
        if args.event == 'BufWritePost' then
          local global_linters = { 'gitleaks' }
          if trivy_enabled then
            table.insert(global_linters, 'trivy')
          end
          lint.try_lint(global_linters)
        end

        -- Run codespell on all events
        lint.try_lint { 'codespell' }
      end,
    })

    -- Show linters for the current buffer's file type
    vim.api.nvim_create_user_command('LintInfo', function()
      local filetype = vim.bo.filetype
      local linters = require('lint').linters_by_ft[filetype]

      if linters then
        print('Linters for ' .. filetype .. ': ' .. table.concat(linters, ', '))
      else
        print('No linters configured for filetype: ' .. filetype)
      end
    end, {})

    -- Toggle trivy linting
    vim.api.nvim_create_user_command('TrivyLintToggle', function()
      trivy_enabled = not trivy_enabled
      local status = trivy_enabled and 'enabled' or 'disabled'
      print('Trivy linting ' .. status)

      if trivy_enabled then
        -- Run trivy immediately if enabled
        lint.try_lint { 'trivy' }
      else
        -- Clear trivy diagnostics when disabled
        local trivy_ns = vim.api.nvim_create_namespace 'trivy'
        vim.diagnostic.reset(trivy_ns, 0)
      end
    end, {})
  end,
}
