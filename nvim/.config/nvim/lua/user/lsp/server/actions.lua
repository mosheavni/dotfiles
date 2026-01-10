-- Custom code actions for the user LSP server
-- Converted from null-ls code-actions.lua

local git = require 'user.git'
local shellcheck = require 'user.lsp.server.shellcheck'
local api = vim.api

local M = {}

local function get_indent(line)
  return string.match(line, '^%s*')
end

--- Build context from LSP params (similar to null-ls context)
---@param params table LSP codeAction params
---@return table context
local function build_context(params)
  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
  local content = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local row = params.range.start.line + 1 -- Convert 0-indexed to 1-indexed

  return {
    bufnr = bufnr,
    content = content,
    range = {
      row = row,
      col = params.range.start.character + 1,
    },
    filetype = vim.bo[bufnr].filetype,
  }
end

-- YAML: ArgoCD revision branch toggle
local function revision_branch_comment(context)
  if context.filetype ~= 'yaml' then
    return {}
  end

  local is_argo_app = vim.iter(context.content):find(function(v)
    return string.find(v, 'kind: Application')
  end)

  if not is_argo_app then
    return {}
  end

  local target_revision_line_number = vim.fn.search('targetRevision: ', 'nw')
  if target_revision_line_number == 0 then
    return {}
  end

  local target_revision_line = context.content[target_revision_line_number]
  local indent = get_indent(target_revision_line)

  if string.find(target_revision_line, 'targetRevision: HEAD') then
    return {
      {
        title = 'Change branch to current',
        kind = 'refactor.rewrite',
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
      kind = 'refactor.rewrite',
      action = function()
        local new_lines = { indent .. 'targetRevision: HEAD' }
        api.nvim_buf_set_lines(context.bufnr, target_revision_line_number - 1, target_revision_line_number, false, new_lines)
      end,
    },
  }
end

-- Groovy/Jenkinsfile: Toggle function params
local function toggle_function_params(context)
  if context.filetype ~= 'groovy' and context.filetype ~= 'Jenkinsfile' then
    return {}
  end

  local row = context.range.row
  local current_line = context.content[row]
  if not current_line then
    return {}
  end

  local is_function = vim.regex([=[\v\s*def\s[^\)]+\(]=]):match_str(current_line)
  if not is_function then
    return {}
  end

  return {
    {
      title = 'Toggle function positional params to map args',
      kind = 'refactor.rewrite',
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

-- Groovy/Jenkinsfile: Toggle library branch
local function library_current_branch(context)
  if context.filetype ~= 'groovy' and context.filetype ~= 'Jenkinsfile' then
    return {}
  end

  local first_line = context.content[1]
  if not first_line or not string.find(first_line, [[@Library%(['"]utils]]) then
    return {}
  end

  if string.find(first_line, [[@Library%(['"]utils@]]) then
    return {
      {
        title = 'Remove current branch from library',
        kind = 'refactor.rewrite',
        action = function()
          api.nvim_buf_set_lines(context.bufnr, 0, 1, false, { "@Library('utils') _" })
        end,
      },
    }
  end

  return {
    {
      title = 'Change library to current branch',
      kind = 'refactor.rewrite',
      action = function()
        local new_line = string.format("@Library('utils@%s') _ // TODO: remove library before merging", git.get_branch_sync())
        api.nvim_buf_set_lines(context.bufnr, 0, 1, false, { new_line })
      end,
    },
  }
end

-- Lua: Selene ignore diagnostic
local function selene_ignore_diagnostic(context)
  if context.filetype ~= 'lua' then
    return {}
  end

  local diagnostics = vim.diagnostic.get(context.bufnr, { lnum = context.range.row - 1 })
  local actions = {}

  for _, diag in ipairs(diagnostics) do
    if diag.source == 'selene' then
      table.insert(actions, {
        title = 'selene: ignore line diagnostic ' .. diag.code,
        kind = 'quickfix',
        action = function()
          local line_number = diag.lnum
          local ignore_comment = string.format('-- selene: allow(%s)', diag.code)
          api.nvim_buf_set_lines(context.bufnr, line_number, line_number, false, { ignore_comment })
        end,
      })
      table.insert(actions, {
        title = 'selene: ignore file diagnostic ' .. diag.code,
        kind = 'quickfix',
        action = function()
          local ignore_comment = string.format('--# selene: allow(%s)', diag.code)
          api.nvim_buf_set_lines(context.bufnr, 0, 0, false, { ignore_comment })
        end,
      })
    end
  end

  return actions
end

-- Markdown: Markdownlint disable diagnostic
local function markdownlint_disable_diagnostic(context)
  if context.filetype ~= 'markdown' then
    return {}
  end

  local diagnostics = vim.diagnostic.get(context.bufnr, { lnum = context.range.row - 1 })
  local actions = {}
  local seen_rules = {}

  for _, diag in ipairs(diagnostics) do
    if diag.source == 'markdownlint' then
      local rule_code = diag.message:match 'error (MD%d+)/'
      if rule_code and not seen_rules[rule_code] then
        seen_rules[rule_code] = true

        table.insert(actions, {
          title = 'markdownlint: disable current line ' .. rule_code,
          kind = 'quickfix',
          action = function()
            local line_number = diag.lnum
            local current_line = api.nvim_buf_get_lines(context.bufnr, line_number, line_number + 1, false)[1]
            local new_line = current_line .. ' <!-- markdownlint-disable-line ' .. rule_code .. ' -->'
            api.nvim_buf_set_lines(context.bufnr, line_number, line_number + 1, false, { new_line })
          end,
        })

        table.insert(actions, {
          title = 'markdownlint: disable next line ' .. rule_code,
          kind = 'quickfix',
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
          kind = 'quickfix',
          action = function()
            local first_line = api.nvim_buf_get_lines(context.bufnr, 0, 1, false)[1]

            local has_disable = first_line and first_line:match '<!%-%-%s*markdownlint%-disable%s+'
            local has_disable_line = first_line and first_line:match 'disable%-line'
            local has_disable_next_line = first_line and first_line:match 'disable%-next%-line'

            if has_disable and not has_disable_line and not has_disable_next_line then
              local new_line = first_line:gsub('(%s*)-->', ' ' .. rule_code .. '%1-->')
              api.nvim_buf_set_lines(context.bufnr, 0, 1, false, { new_line })
            else
              local ignore_comment = '<!-- markdownlint-disable ' .. rule_code .. ' -->'
              api.nvim_buf_set_lines(context.bufnr, 0, 0, false, { ignore_comment })
            end
          end,
        })
      end
    end
  end

  return actions
end

-- List of all action generators
local action_generators = {
  revision_branch_comment,
  toggle_function_params,
  library_current_branch,
  selene_ignore_diagnostic,
  markdownlint_disable_diagnostic,
}

--- Get all applicable actions for the given LSP params
---@param params table LSP codeAction params
---@return table[] actions
function M.get_actions(params)
  local context = build_context(params)
  local all_actions = {}

  for _, generator in ipairs(action_generators) do
    local actions = generator(context)
    for _, action in ipairs(actions) do
      table.insert(all_actions, action)
    end
  end

  -- Add shellcheck actions (handles its own filetype check)
  for _, action in ipairs(shellcheck.get_actions(context)) do
    table.insert(all_actions, action)
  end

  return all_actions
end

return M
