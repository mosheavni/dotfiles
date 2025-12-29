local git = require 'user.git'
local null_ls = require 'null-ls'

local M = {}
local api = vim.api

local function get_indent(line)
  return string.match(line, '^%s*')
end

M.revision_branch_comment = {
  method = null_ls.methods.CODE_ACTION,
  filetypes = { 'yaml' },
  name = 'Revision branch comment',
  generator = {
    fn = function(context)
      local is_argo_app = vim.iter(context.content):find(function(v)
        return string.find(v, 'kind: Application')
      end)

      -- check if current line has the substring 'targetRevision: '
      if is_argo_app then
        local target_revision_line_number = vim.fn.search('targetRevision: ', 'nw')
        local target_revision_line = context.content[target_revision_line_number]
        local indent = get_indent(target_revision_line)

        if string.find(target_revision_line, 'targetRevision: HEAD') then
          return {
            {
              title = 'Change branch to current',
              action = function()
                local new_lines = {
                  indent .. 'targetRevision: ' .. git.get_branch_sync() .. ' # TODO: Change to HEAD before merging',
                }
                api.nvim_buf_set_lines(context.bufnr, target_revision_line_number - 1, target_revision_line_number, false, new_lines)
              end,
            },
          }
        end

        return {
          {
            title = 'Change branch to HEAD',
            action = function()
              local new_lines = { indent .. 'targetRevision: HEAD' }
              api.nvim_buf_set_lines(context.bufnr, target_revision_line_number - 1, target_revision_line_number, false, new_lines)
            end,
          },
        }
      end
    end,
  },
}

M.toggle_function_params = {
  method = null_ls.methods.CODE_ACTION,
  filetypes = { 'groovy', 'Jenkinsfile' },
  name = 'Toggle function positional params to map args',
  generator = {
    fn = function(context)
      local row = context.range.row
      local current_line = context.content[row]
      local is_function = vim.regex([=[\v\s*def\s[^\)]+\(]=]):match_str(current_line)

      if is_function then
        return {
          {
            title = 'Toggle function positional params to map args',
            action = function()
              local function_args = current_line:gsub([=[%s*def%s%w+%((.*)%).*]=], '%1')
              function_args = function_args:gsub('%s?=%s?', '=')
              function_args = function_args:gsub('%s?:%s?', ':')
              local final

              if string.find(function_args, 'Map args=') then
                function_args = function_args:gsub('Map args=%[(.*)%]', '%1')
                function_args = function_args:gsub('(%w+):([^,]*)', '%1=%2')
                final = current_line:gsub([=[(%s*def%s%w+%().*(%).*)]=], '%1' .. function_args .. '%2')
              else
                function_args = function_args:gsub('(%w+)=([^,]*)', '%1:%2')
                final = current_line:gsub([=[(%s*def%s%w+%().*(%).*)]=], '%1Map args=[' .. function_args .. ']%2')
              end

              api.nvim_buf_set_lines(context.bufnr, row - 1, row, false, { final })
            end,
          },
        }
      end
    end,
  },
}

M.library_current_branch = {
  method = null_ls.methods.CODE_ACTION,
  filetypes = { 'groovy', 'Jenkinsfile' },
  name = 'Toggle library current branch',
  generator = {
    fn = function(context)
      local first_line = context.content[1]
      if string.find(first_line, [[@Library%(['"]utils]]) then
        if string.find(first_line, [[@Library%(['"]utils@]]) then
          return {
            {
              title = 'Remove current branch from library',
              action = function()
                api.nvim_buf_set_lines(context.bufnr, 0, 1, false, { "@Library('utils') _" })
              end,
            },
          }
        end

        return {
          {
            title = 'Change library to current branch',
            action = function()
              local new_line = string.format("@Library('utils@%s') _ // TODO: remove library before merging", git.get_branch_sync())
              api.nvim_buf_set_lines(context.bufnr, 0, 1, false, { new_line })
            end,
          },
        }
      end
    end,
  },
}

M.selene_ignore_diagnostic = {
  method = null_ls.methods.CODE_ACTION,
  filetypes = { 'lua' },
  name = 'Selene ignore diagnostic',
  generator = {
    fn = function(context)
      local diagnostics = vim.diagnostic.get(context.bufnr, { lnum = context.range.row - 1 })
      local actions = {}
      for _, diag in ipairs(diagnostics) do
        if diag.source == 'selene' then
          table.insert(actions, {
            title = 'selene: ignore line diagnostic ' .. diag.code,
            action = function()
              local line_number = diag.lnum
              -- add "-- selene: allow(<code>)" one line above the diagnostic line
              local ignore_comment = string.format('-- selene: allow(%s)', diag.code)
              api.nvim_buf_set_lines(context.bufnr, line_number, line_number, false, { ignore_comment })
            end,
          })
          table.insert(actions, {
            title = 'selene: ignore file diagnostic ' .. diag.code,
            action = function()
              local ignore_comment = string.format('--# selene: allow(%s)', diag.code)
              api.nvim_buf_set_lines(context.bufnr, 0, 0, false, { ignore_comment })
            end,
          })
        end
      end
      return actions
    end,
  },
}

M.markdownlint_disable_diagnostic = {
  method = null_ls.methods.CODE_ACTION,
  filetypes = { 'markdown' },
  name = 'Markdownlint disable diagnostic',
  generator = {
    fn = function(context)
      local diagnostics = vim.diagnostic.get(context.bufnr, { lnum = context.range.row - 1 })
      local actions = {}
      local seen_rules = {}

      for _, diag in ipairs(diagnostics) do
        if diag.source == 'markdownlint' then
          -- Extract rule code from message like "error MD041/first-line-heading/..."
          local rule_code = diag.message:match('error (MD%d+)/')
          if rule_code and not seen_rules[rule_code] then
            seen_rules[rule_code] = true
            table.insert(actions, {
              title = 'markdownlint: disable current line ' .. rule_code,
              action = function()
                local line_number = diag.lnum
                local current_line = api.nvim_buf_get_lines(context.bufnr, line_number, line_number + 1, false)[1]
                local new_line = current_line .. ' <!-- markdownlint-disable-line ' .. rule_code .. ' -->'
                api.nvim_buf_set_lines(context.bufnr, line_number, line_number + 1, false, { new_line })
              end,
            })
            table.insert(actions, {
              title = 'markdownlint: disable next line ' .. rule_code,
              action = function()
                local line_number = diag.lnum
                local current_line_content = api.nvim_buf_get_lines(context.bufnr, line_number, line_number + 1, false)[1]
                local indent = get_indent(current_line_content)
                local ignore_comment = indent .. '<!-- markdownlint-disable-next-line ' .. rule_code .. ' -->'
                api.nvim_buf_set_lines(context.bufnr, line_number, line_number, false, { ignore_comment })
              end,
            })
            table.insert(actions, {
              title = 'markdownlint: disable file ' .. rule_code,
              action = function()
                -- Check if first line has markdownlint-disable comment
                local first_line = api.nvim_buf_get_lines(context.bufnr, 0, 1, false)[1]
                vim.print('first_line: ' .. vim.inspect(first_line))

                local has_disable = first_line and first_line:match('<!%-%-%s*markdownlint%-disable%s+')
                local has_disable_line = first_line and first_line:match('disable%-line')
                local has_disable_next_line = first_line and first_line:match('disable%-next%-line')

                vim.print('has_disable: ' .. vim.inspect(has_disable))
                vim.print('has_disable_line: ' .. vim.inspect(has_disable_line))
                vim.print('has_disable_next_line: ' .. vim.inspect(has_disable_next_line))

                if has_disable and not has_disable_line and not has_disable_next_line then
                  -- Append to existing disable comment
                  vim.print('Appending to existing line')
                  local new_line = first_line:gsub('(%s*)-->', ' ' .. rule_code .. '%1-->')
                  vim.print('new_line: ' .. vim.inspect(new_line))
                  api.nvim_buf_set_lines(context.bufnr, 0, 1, false, { new_line })
                else
                  -- Create new disable comment
                  vim.print('Creating new line')
                  local ignore_comment = '<!-- markdownlint-disable ' .. rule_code .. ' -->'
                  api.nvim_buf_set_lines(context.bufnr, 0, 0, false, { ignore_comment })
                end
              end,
            })
          end
        end
      end
      return actions
    end,
  },
}

return M
