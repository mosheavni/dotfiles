-- Custom code actions for the user LSP server
-- Converted from null-ls code-actions.lua

local git = require 'user.git'
local shellcheck = require 'user.lsp.server.shellcheck'
local api = vim.api

local M = {}

local function get_indent(line)
  return string.match(line, '^%s*')
end

--- Build an LSP text edit
---@param line_start number 0-indexed start line
---@param line_end number 0-indexed end line
---@param new_text string text to insert
---@return table edit
local function make_edit(line_start, line_end, new_text)
  return {
    range = {
      start = { line = line_start, character = 0 },
      ['end'] = { line = line_end, character = 0 },
    },
    newText = new_text,
  }
end

-- Action builder: insert comment above current line (for "next line" ignore directives)
---@param opts table { title_fmt, check_existing, format_new, format_merge }
---@return table action_builder
local function next_line_action(opts)
  return {
    build = function(context, uri, line_number, _, indent, rule)
      local prev_line = line_number > 0 and context.content[line_number] or ''
      local existing = opts.check_existing(prev_line)

      local edit
      if existing then
        edit = make_edit(line_number - 1, line_number, opts.format_merge(prev_line, rule))
      else
        edit = make_edit(line_number, line_number, opts.format_new(rule, indent))
      end

      return {
        title = string.format(opts.title_fmt, rule),
        kind = 'quickfix',
        edit = { changes = { [uri] = { edit } } },
      }
    end,
  }
end

-- Action builder: append comment to current line (for "current line" ignore directives)
---@param opts table { title_fmt, check_existing, format_new, format_merge }
---@return table action_builder
local function current_line_action(opts)
  return {
    build = function(_, uri, line_number, current_line, _, rule)
      local existing = opts.check_existing(current_line)
      local new_text = existing and opts.format_merge(current_line, rule) or opts.format_new(current_line, rule)

      return {
        title = string.format(opts.title_fmt, rule),
        kind = 'quickfix',
        edit = { changes = { [uri] = { make_edit(line_number, line_number + 1, new_text) } } },
      }
    end,
  }
end

-- Action builder: insert comment at file top (for file-level ignore directives)
---@param opts table { title_fmt, check_existing, format_new, format_merge }
---@return table action_builder
local function file_action(opts)
  return {
    build = function(context, uri, _, _, _, rule)
      local first_line = context.content[1] or ''
      local existing = opts.check_existing(first_line)

      local edit
      if existing then
        edit = make_edit(0, 1, opts.format_merge(first_line, rule))
      else
        edit = make_edit(0, 0, opts.format_new(rule))
      end

      return {
        title = string.format(opts.title_fmt, rule),
        kind = 'quickfix',
        edit = { changes = { [uri] = { edit } } },
      }
    end,
  }
end

--- Create a lint ignore action generator from config
---@param config table { filetypes, source, actions }
---@return function generator
local function create_lint_ignore_generator(config)
  return function(context)
    -- Check filetype
    local ft_match = false
    for _, ft in ipairs(config.filetypes) do
      if context.filetype == ft then
        ft_match = true
        break
      end
    end
    if not ft_match then
      return {}
    end

    local diagnostics = vim.diagnostic.get(context.bufnr, { lnum = context.range.row - 1 })
    local actions = {}
    local seen_rules = {}
    local uri = vim.uri_from_bufnr(context.bufnr)

    for _, diag in ipairs(diagnostics) do
      if diag.source == config.source then
        local rule_code = diag.code
        if rule_code and not seen_rules[rule_code] then
          seen_rules[rule_code] = true
          local line_number = diag.lnum
          local current_line = context.content[line_number + 1] or ''
          local indent = get_indent(current_line)

          for _, action_config in ipairs(config.actions) do
            local action = action_config.build(context, uri, line_number, current_line, indent, rule_code)
            if action then
              table.insert(actions, action)
            end
          end
        end
      end
    end
    return actions
  end
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
    local uri = vim.uri_from_bufnr(context.bufnr)
    local new_text = indent .. 'targetRevision: ' .. git.get_branch_sync() .. ' # TODO: Change to HEAD before merging\n'
    return {
      {
        title = 'Change branch to current',
        kind = 'refactor.rewrite',
        edit = {
          changes = {
            [uri] = {
              {
                range = {
                  start = { line = target_revision_line_number - 1, character = 0 },
                  ['end'] = { line = target_revision_line_number, character = 0 },
                },
                newText = new_text,
              },
            },
          },
        },
      },
    }
  end

  local uri = vim.uri_from_bufnr(context.bufnr)
  return {
    {
      title = 'Change branch to HEAD',
      kind = 'refactor.rewrite',
      edit = {
        changes = {
          [uri] = {
            {
              range = {
                start = { line = target_revision_line_number - 1, character = 0 },
                ['end'] = { line = target_revision_line_number, character = 0 },
              },
              newText = indent .. 'targetRevision: HEAD\n',
            },
          },
        },
      },
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

  -- Compute the new text
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

  local uri = vim.uri_from_bufnr(context.bufnr)
  return {
    {
      title = 'Toggle function positional params to map args',
      kind = 'refactor.rewrite',
      edit = {
        changes = {
          [uri] = {
            {
              range = {
                start = { line = row - 1, character = 0 },
                ['end'] = { line = row, character = 0 },
              },
              newText = final .. '\n',
            },
          },
        },
      },
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

  local uri = vim.uri_from_bufnr(context.bufnr)
  if string.find(first_line, [[@Library%(['"]utils@]]) then
    return {
      {
        title = 'Remove current branch from library',
        kind = 'refactor.rewrite',
        edit = {
          changes = {
            [uri] = {
              {
                range = {
                  start = { line = 0, character = 0 },
                  ['end'] = { line = 1, character = 0 },
                },
                newText = "@Library('utils') _\n",
              },
            },
          },
        },
      },
    }
  end

  local new_line = string.format("@Library('utils@%s') _ // TODO: remove library before merging\n", git.get_branch_sync())
  return {
    {
      title = 'Change library to current branch',
      kind = 'refactor.rewrite',
      edit = {
        changes = {
          [uri] = {
            {
              range = {
                start = { line = 0, character = 0 },
                ['end'] = { line = 1, character = 0 },
              },
              newText = new_line,
            },
          },
        },
      },
    },
  }
end

-- Groovy: npm-groovy-lint ignore diagnostics
local groovylint_ignore = create_lint_ignore_generator({
  filetypes = { 'groovy', 'Jenkinsfile' },
  source = 'npm-groovy-lint',
  actions = {
    current_line_action({
      title_fmt = 'groovylint: disable current line %s',
      check_existing = function(line)
        return line:match '// groovylint%-disable%-line'
      end,
      format_new = function(line, rule)
        return line .. ' // groovylint-disable-line ' .. rule .. '\n'
      end,
      format_merge = function(line, rule)
        return line:gsub('// groovylint%-disable%-line%s+(.+)$', '// groovylint-disable-line %1, ' .. rule) .. '\n'
      end,
    }),
    next_line_action({
      title_fmt = 'groovylint: disable next line %s',
      check_existing = function(line)
        return line:match '// groovylint%-disable%-next%-line'
      end,
      format_new = function(rule, indent)
        return indent .. '// groovylint-disable-next-line ' .. rule .. '\n'
      end,
      format_merge = function(line, rule)
        return line:gsub('// groovylint%-disable%-next%-line%s+(.+)$', '// groovylint-disable-next-line %1, ' .. rule)
          .. '\n'
      end,
    }),
    file_action({
      title_fmt = 'groovylint: disable file %s',
      check_existing = function(line)
        return line:match '%/%*%s*groovylint%-disable'
      end,
      format_new = function(rule)
        return '/* groovylint-disable ' .. rule .. ' */\n'
      end,
      format_merge = function(line, rule)
        return line:gsub('%/%*%s*groovylint%-disable%s+([^%*]+)%s*%*%/', '/* groovylint-disable %1, ' .. rule .. ' */')
          .. '\n'
      end,
    }),
  },
})

-- Lua: Selene ignore diagnostics
local selene_ignore = create_lint_ignore_generator({
  filetypes = { 'lua' },
  source = 'selene',
  actions = {
    next_line_action({
      title_fmt = 'selene: ignore line diagnostic %s',
      check_existing = function()
        return nil
      end, -- selene doesn't merge
      format_new = function(rule, indent)
        return indent .. '-- selene: allow(' .. rule .. ')\n'
      end,
      format_merge = function() end, -- never called
    }),
    file_action({
      title_fmt = 'selene: ignore file diagnostic %s',
      check_existing = function()
        return nil
      end,
      format_new = function(rule)
        return '--# selene: allow(' .. rule .. ')\n'
      end,
      format_merge = function() end,
    }),
  },
})

-- Dockerfile: Hadolint ignore diagnostics
local hadolint_ignore = create_lint_ignore_generator({
  filetypes = { 'dockerfile' },
  source = 'hadolint',
  actions = {
    next_line_action({
      title_fmt = 'hadolint: ignore next line %s',
      check_existing = function(line)
        return line:match '# hadolint ignore='
      end,
      format_new = function(rule, indent)
        return indent .. '# hadolint ignore=' .. rule .. '\n'
      end,
      format_merge = function(line, rule)
        return line:gsub('(# hadolint ignore=.+)$', '%1,' .. rule) .. '\n'
      end,
    }),
    file_action({
      title_fmt = 'hadolint: ignore file %s',
      check_existing = function(line)
        return line:match '# hadolint global ignore='
      end,
      format_new = function(rule)
        return '# hadolint global ignore=' .. rule .. '\n'
      end,
      format_merge = function(line, rule)
        return line:gsub('(# hadolint global ignore=.+)$', '%1,' .. rule) .. '\n'
      end,
    }),
  },
})

-- Markdown: Markdownlint disable diagnostic
local function markdownlint_disable_diagnostic(context)
  if context.filetype ~= 'markdown' then
    return {}
  end

  local diagnostics = vim.diagnostic.get(context.bufnr, { lnum = context.range.row - 1 })
  local actions = {}
  local seen_rules = {}
  local uri = vim.uri_from_bufnr(context.bufnr)

  for _, diag in ipairs(diagnostics) do
    if diag.source == 'markdownlint' then
      local rule_code = diag.message:match 'error (MD%d+)/'
      if rule_code and not seen_rules[rule_code] then
        seen_rules[rule_code] = true

        local line_number = diag.lnum
        local current_line = context.content[line_number + 1] or ''
        local new_line = current_line .. ' <!-- markdownlint-disable-line ' .. rule_code .. ' -->\n'

        table.insert(actions, {
          title = 'markdownlint: disable current line ' .. rule_code,
          kind = 'quickfix',
          edit = {
            changes = {
              [uri] = {
                {
                  range = {
                    start = { line = line_number, character = 0 },
                    ['end'] = { line = line_number + 1, character = 0 },
                  },
                  newText = new_line,
                },
              },
            },
          },
        })

        local indent = get_indent(current_line)
        local ignore_comment = indent .. '<!-- markdownlint-disable-next-line ' .. rule_code .. ' -->\n'

        table.insert(actions, {
          title = 'markdownlint: disable next line ' .. rule_code,
          kind = 'quickfix',
          edit = {
            changes = {
              [uri] = {
                {
                  range = {
                    start = { line = line_number, character = 0 },
                    ['end'] = { line = line_number, character = 0 },
                  },
                  newText = ignore_comment,
                },
              },
            },
          },
        })

        -- File-level disable: check if we should modify existing or insert new
        local first_line = context.content[1] or ''
        local has_disable = first_line:match '<!%-%-%s*markdownlint%-disable%s+'
        local has_disable_line = first_line:match 'disable%-line'
        local has_disable_next_line = first_line:match 'disable%-next%-line'

        local file_edit
        if has_disable and not has_disable_line and not has_disable_next_line then
          -- Modify existing disable comment
          local modified_line = first_line:gsub('(%s*)-->', ' ' .. rule_code .. '%1-->') .. '\n'
          file_edit = {
            range = {
              start = { line = 0, character = 0 },
              ['end'] = { line = 1, character = 0 },
            },
            newText = modified_line,
          }
        else
          -- Insert new disable comment
          file_edit = {
            range = {
              start = { line = 0, character = 0 },
              ['end'] = { line = 0, character = 0 },
            },
            newText = '<!-- markdownlint-disable ' .. rule_code .. ' -->\n',
          }
        end

        table.insert(actions, {
          title = 'markdownlint: disable file ' .. rule_code,
          kind = 'quickfix',
          edit = {
            changes = {
              [uri] = { file_edit },
            },
          },
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
  groovylint_ignore,
  selene_ignore,
  hadolint_ignore,
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
