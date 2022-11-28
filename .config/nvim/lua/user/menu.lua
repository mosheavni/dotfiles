local utils = require 'user.utils'
-- local opts = utils.map_opts
local keymap = utils.keymap
local pretty_print = utils.pretty_print
local dap_actions = require('user.plugins.dap').actions
local git_actions = require('user.git').actions
local lsp_actions = require('user.lsp').actions

local find_in_project = function(bang)
  vim.ui.input({ prompt = 'Enter search term (blank for word under cursor)' }, function(search_term)
    if search_term then
      search_term = ' ' .. search_term
    end

    local bang_str = bang and '!' or ''

    vim.cmd('RipGrepCWORD' .. bang_str .. search_term)
  end)
end

local T = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local random_actions = {
  ['Find in pwd (literal search)'] = function()
    find_in_project(true)
  end,
  ['Find in pwd (regex search)'] = function()
    find_in_project(false)
  end,
  ['Replace word under cursor'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'r')
  end,
  ['Select all'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'sa')
  end,
  ['Duplicate / Copy number of lines'] = function()
    vim.ui.input({ prompt = 'How many lines down?' }, function(lines_down)
      if not lines_down then
        lines_down = ''
      end
      vim.fn.feedkeys(lines_down .. T '<leader>' .. 'cp')
    end)
  end,
  ['Center Focus'] = function()
    vim.fn.feedkeys 'zz'
  end,
  ['Bottom Focus'] = function()
    vim.fn.feedkeys 'zb'
  end,
  ['Top Focus'] = function()
    vim.fn.feedkeys 'zt'
  end,
  ['Record Macro'] = function()
    vim.ui.input({ prompt = 'Macro letter' }, function(macro_letter)
      if not macro_letter then
        macro_letter = 'q'
      end
      vim.fn.feedkeys('q' .. macro_letter)
      pretty_print('Recording macro ' .. macro_letter .. ' (hit q when finished)', 'Macro')
      pretty_print('You can repeat this macro with @' .. macro_letter, 'Macro')
    end)
  end,

  ['Repeat Macro'] = function()
    vim.ui.input({ prompt = 'Macro letter' }, function(macro_letter)
      if not macro_letter then
        macro_letter = 'q'
      end
      vim.ui.input({ prompt = 'How many times? (leave blank for once)' }, function(macro_times)
        if not macro_times then
          macro_times = ''
        end
        vim.fn.feedkeys(macro_times .. '@' .. macro_letter)
      end)
    end)
  end,
}

-- add-prefix function
-- receives a table of functions and returns a table of functions with the
-- prefix added to the key
local function add_prefix(actions, prefix)
  local prefixed_actions = {}
  for k, v in pairs(actions) do
    prefixed_actions[prefix .. ' - ' .. k] = v
  end
  return prefixed_actions
end

-- Merge all actions and prepend type to the name using add_prefix function
-- I.E: Git - Delete tag
-- I.E: Dap - Continue
local actions = vim.tbl_extend('force', add_prefix(dap_actions, 'DAP'), add_prefix(git_actions, 'Git'), add_prefix(lsp_actions, 'LSP'), random_actions)

keymap('n', '<leader>a', function()
  vim.ui.select(vim.tbl_keys(actions), { prompt = 'Choose action' }, function(choice)
    if choice then
      actions[choice]()
    end
  end)
end)
