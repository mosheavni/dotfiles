local utils = require 'telescope.utils'
local strings = require 'plenary.strings'
local entry_display = require 'telescope.pickers.entry_display'
local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local actions = require 'telescope.actions'
local previewers = require 'telescope.previewers'
local conf = require('telescope.config').values

local open = function()
  local opts = {}

  local format = '%(HEAD)' .. '%(refname)' .. '%(authorname)' .. '%(upstream:lstrip=2)' .. '%(committerdate:format-local:%Y/%m/%d %H:%M:%S)'
  -- local format = '%(HEAD)' .. '%(refname)' .. '%(upstream:lstrip=2)' .. '%(committerdate:format-local:%Y/%m/%d %H:%M:%S)'
  local output = utils.get_os_command_output({ 'git', 'for-each-ref', '--perl', '--sort', 'committerdate', '--format', format, opts.pattern }, opts.cwd)
  local remotes = utils.get_os_command_output({ 'git', 'remote' }, opts.cwd)

  local results = {}
  local widths = {
    name = 0,
    authorname = 0,
    -- upstream = 0,
    committerdate = 20,
  }
  local unescape_single_quote = function(v)
    return string.gsub(v, "\\([\\'])", '%1')
  end
  local parsed_branches = {}
  local parse_line = function(line)
    local fields = vim.split(string.sub(line, 2, -2), "''", true)
    local entry = {
      head = fields[1],
      refname = unescape_single_quote(fields[2]),
      authorname = unescape_single_quote(fields[3]),
      upstream = unescape_single_quote(fields[4]),
      committerdate = fields[5],
    }

    -- Entry name
    local prefix
    if vim.startswith(entry.refname, 'refs/remotes/') then
      prefix = 'refs/remotes/'
    elseif vim.startswith(entry.refname, 'refs/heads/') then
      prefix = 'refs/heads/'
    else
      return
    end
    entry.value = string.sub(entry.refname, string.len(prefix) + 1)
    entry.name = entry.value
    for _, remote in pairs(remotes) do
      if vim.startswith(entry.value, remote .. '/') then
        entry.name = string.sub(entry.value, string.len(remote) + 2)
      end
    end

    -- Don't return existing branches
    if vim.tbl_contains(parsed_branches, entry.name) then
      return
    end

    -- Don't return HEAD
    if entry.name == 'HEAD' then
      return
    end

    -- Widths
    for key, value in pairs(widths) do
      widths[key] = math.max(value, strings.strdisplaywidth(entry[key] or ''))
    end
    -- if string.len(entry.upstream) > 0 then
    --   widths.upstream_indicator = 2
    -- end
    table.insert(parsed_branches, entry.name)
    return entry
  end
  local head
  for _, line in ipairs(output) do
    local parsed_line = parse_line(line)
    if not parsed_line then
      goto continue
    end
    if parsed_line.head ~= '*' then
      table.insert(results, 1, parsed_line)
    else
      head = parsed_line
    end
    ::continue::
  end
  if #results == 0 then
    return
  end
  if head then
    table.insert(results, 1, head)
  end

  local displayer = entry_display.create {
    separator = ' ',
    items = {
      { width = 1 },
      { width = widths.name },
      { width = widths.authorname },
      -- { width = widths.upstream_indicator },
      -- { width = widths.upstream },
      { width = widths.committerdate },
    },
  }

  local make_display = function(entry)
    return displayer {
      { entry.head },
      { entry.name, 'TelescopeResultsIdentifier' },
      { entry.authorname },
      -- { string.len(entry.upstream) > 0 and '=>' or '' },
      -- { entry.upstream, 'TelescopeResultsIdentifier' },
      { entry.committerdate },
    }
  end

  -- TODO: checkout and set remote to new branch instead of just checking out

  pickers.new(opts, {
    prompt_title = 'Git Branches',
    finder = finders.new_table {
      results = results,
      entry_maker = function(entry)
        entry.name = entry.name
        entry.value = entry.name
        entry.ordinal = entry.value
        entry.display = make_display
        return entry
      end,
    },
    previewer = previewers.git_branch_log.new(opts),
    sorter = conf.generic_sorter(opts),

    attach_mappings = function(_, map)
      actions.select_default:replace(actions.git_checkout)
      -- map('i', '<cr>', actions.git_checkout)
      -- map('n', '<cr>', actions.git_checkout)

      map('i', '<c-r>', actions.git_rebase_branch)
      map('n', '<c-r>', actions.git_rebase_branch)

      map('i', '<c-a>', actions.git_create_branch)
      map('n', '<c-a>', actions.git_create_branch)

      map('i', '<c-s>', actions.git_switch_branch)
      map('n', '<c-s>', actions.git_switch_branch)

      map('i', '<c-d>', actions.git_delete_branch)
      map('n', '<c-d>', actions.git_delete_branch)

      map('i', '<c-y>', actions.git_merge_branch)
      map('n', '<c-y>', actions.git_merge_branch)
      return true
    end,
  }):find()
end

return {
  open = open,
}
