local null_ls = require 'null-ls'

local M = {}
M.revision_branch_comment = {
  method = null_ls.methods.CODE_ACTION,
  filetypes = { 'yaml' },
  generator = {
    fn = function(context)
      local row = context.range.row
      local current_line = context.content[row]
      -- check if current line has the substring 'targetRevision: '
      if string.find(current_line, 'targetRevision: ') then
        return {
          {
            title = 'Change branch to current',
            action = function()
              -- get indentation of current_line
              local indent = string.match(current_line, '^%s*')
              local new_lines = { indent .. 'targetRevision: ' .. vim.fn.FugitiveHead() .. ' # TODO: Change to HEAD before merging' }
              vim.api.nvim_buf_set_lines(context.bufnr, row - 1, row, false, new_lines)
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
  generator = {
    fn = function(context)
      local row = context.range.row
      local current_line = context.content[row]
      local is_function = vim.regex([=[\v\s*def\s[^\)]+\(]=]):match_str(current_line)
      local final = current_line
      if is_function then
        return {
          {
            title = 'Toggle function positional params to map args',
            action = function()
              local function_args = current_line:gsub([=[%s*def%s%w+%((.*)%).*]=], '%1')
              function_args = function_args:gsub('%s?=%s?', '=')
              function_args = function_args:gsub('%s?:%s?', ':')
              if string.find(function_args, 'Map args=') then
                function_args = function_args:gsub('Map args=%[(.*)%]', '%1')
                function_args = function_args:gsub('(%w+):([^,]*)', '%1=%2')
                final = current_line:gsub([=[(%s*def%s%w+%().*(%).*)]=], '%1' .. function_args .. '%2')
              else
                function_args = function_args:gsub('(%w+)=([^,]*)', '%1:%2')
                final = current_line:gsub([=[(%s*def%s%w+%().*(%).*)]=], '%1Map args=[' .. function_args .. ']%2')
              end
              -- function_args = string.gsub(function_args, [[\w+:\w+]], '')
              -- P(function_args)
              vim.api.nvim_buf_set_lines(context.bufnr, row - 1, row, false, { final })
            end,
          },
        }
      end
    end,
  },
}

return M
