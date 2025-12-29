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
      vim.print('actions: ' .. vim.inspect(actions))
      return actions
    end,
  },
}

return M
