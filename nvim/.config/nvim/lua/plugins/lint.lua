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

    lint.linters_by_ft = {
      -- hcl = { 'terragrunt_validate' },
      Jenkinsfile = { 'npm-groovy-lint' },
      ['docker-compose'] = { 'dclint' },
      dockerfile = { 'hadolint' },
      ghaction = { 'actionlint' },
      groovy = { 'npm-groovy-lint' },
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
      callback = function()
        if vim.bo.modifiable then
          -- Get linters for current filetype
          local linters = lint._resolve_linter_by_ft(vim.bo.filetype)

          -- Run each linter with its configured cwd
          for _, linter_name in ipairs(linters) do
            local cwd = get_linter_cwd(linter_name)
            lint.try_lint(linter_name, { cwd = cwd })
          end

          -- generic
          lint.try_lint { 'gitleaks', 'codespell', 'trivy' }
        end
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
  end,
}
