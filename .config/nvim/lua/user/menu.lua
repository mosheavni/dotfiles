local utils = require 'user.utils'
-- local opts = utils.map_opts
local nmap = utils.nmap
local pretty_print = utils.pretty_print

local M = {}
M.git_actions = require('user.plugins.git').actions
M.lsp_actions = require('user.lsp').actions
M.dap_actions = {}

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

M.random_actions = {
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
  ['Indent block forward'] = function()
    vim.fn.feedkeys(T '<leader>gt')
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
  ['Toggle Terminal'] = function()
    vim.fn.feedkeys(T '<F6>')
  end,
  ['Create a new terminal window'] = function()
    vim.fn.feedkeys(T '<F7>')
  end,
  ['Move to next terminal window'] = function()
    vim.fn.feedkeys(T '<F8>')
  end,
  ['Find files'] = function()
    vim.fn.feedkeys(T '<C-p>')
  end,
  ['Find buffers'] = function()
    vim.fn.feedkeys(T '<C-b>')
  end,
  ['Open Nvim Tree File Browser'] = function()
    vim.fn.feedkeys(T '<C-o>')
  end,
  ['Close all notifications'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'x')
  end,
  ['Quit all'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'qq')
  end,
  ['Paste from clipboard'] = function()
    vim.fn.feedkeys(T '<C-v>')
  end,
  ['Copy entire file to clipboard'] = function()
    vim.fn.feedkeys 'Y'
  end,
  ['Convert \\n to new lines'] = function()
    vim.fn.feedkeys(T '<leader>' .. T '<cr>')
  end,
  ['Move line down'] = function()
    vim.fn.feedkeys '-'
  end,
  ['Move line up'] = function()
    vim.fn.feedkeys '_'
  end,
  ['Copy full file path to clipboard'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'cfa')
  end,
  ['Copy relative file path to clipboard'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'cfp')
  end,
  ['Copy directory path to clipboard'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'cfd')
  end,
  ['Split long bash line'] = function()
    vim.fn.feedkeys(T '<leader>' .. [[\]])
  end,
  ['Delete all hidden buffers'] = function()
    vim.cmd 'BDelete hidden'
  end,
  ['Delete current buffer'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'bd')
  end,
  ['Yaml to Json'] = function()
    vim.cmd.Yaml2Json()
  end,
  ['Json to Yaml'] = function()
    vim.cmd.Json2Yaml()
  end,
  ['Change indent size'] = function()
    vim.cmd.Json2Yaml()
    vim.fn.feedkeys 'cii'
  end,
  ['Convert tabs to spaces'] = function()
    local original_expandtab = vim.opt_global.expandtab:get()
    vim.opt.expandtab = true
    vim.cmd.retab()
    vim.opt.expandtab = original_expandtab
  end,
  ['Diff unsaved with saved file'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'ds')
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

M.set_actions = function()
  M.actions = vim.tbl_extend('force', add_prefix(M.dap_actions, 'DAP'), add_prefix(M.git_actions, 'Git'), add_prefix(M.lsp_actions, 'LSP'), M.random_actions)
end

M.set_dap_actions = function()
  M.dap_actions = require('user.plugins.dap').actions
  M.set_actions()
end

M.setup = function()
  M.set_actions()
  nmap('<leader>a', function()
    vim.ui.select(vim.tbl_keys(M.actions), { prompt = 'Choose action (' .. vim.tbl_count(M.actions) .. ' actions)' }, function(choice)
      if choice then
        M.actions[choice]()
      end
    end)
  end)
end

return M
