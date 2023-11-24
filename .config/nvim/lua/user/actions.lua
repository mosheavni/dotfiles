local utils = require 'user.utils'
local pretty_print = utils.pretty_print
local find_in_project = function(opts)
  opts = opts or {
    literal_search = true,
    callback = function() end,
    noautocmd = false,
  }
  local bang = opts.literal_search and '' or '!'
  local noautocmd_str = opts.noautocmd and 'noautocmd ' or ''
  vim.ui.input({ prompt = 'Enter search term (blank for word under cursor): ' }, function(search_term)
    local original_search_term = search_term
    if search_term then
      search_term = ' ' .. search_term
    end

    vim.cmd(noautocmd_str .. 'RipGrepCWORD' .. bang .. search_term)
    opts.callback(original_search_term)
  end)
end

local search_and_replace = function(literal_search)
  find_in_project {
    literal_search = literal_search,
    callback = function(search_term)
      vim.ui.input({ prompt = 'Enter Replace term: ' }, function(replace_term)
        if not replace_term then
          pretty_print 'Canceled.'
          return
        end
        vim.ui.input({
          prompt = 'Enter flags (g=global, c=confirm, i=case insensitive, e=ignore errors, n=only count): ',
          default = 'gce',
        }, function(flags)
          if not flags then
            pretty_print 'Canceled.'
            return
          end
          vim.cmd('silent noautocmd cdo %s?' .. search_term .. '?' .. replace_term .. '?' .. flags)
        end)
      end)
    end,
    noautocmd = true,
  }
end

local T = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

return {
  ['Find in pwd (literal search) (<C-f>)'] = function()
    find_in_project { literal_search = true }
  end,
  ['Find in pwd (regex search) (<C-f>)'] = function()
    find_in_project { literal_search = false }
  end,
  ['Search and Replace in pwd (literal search)'] = function()
    search_and_replace(true)
  end,
  ['Search and Replace in pwd (regex search)'] = function()
    search_and_replace(false)
  end,
  ['Replace word under cursor (<leader>r)'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'r')
  end,
  ['Select all (vae / <leader>sa)'] = function()
    vim.cmd [[normal! ggVG]]
  end,
  ['Indent block forward (<leader>gt)'] = function()
    vim.cmd [[normal! v%koj$>]]
  end,
  ['Open all folds (zR / <leader>fo)'] = function()
    vim.cmd 'normal! zR'
  end,
  ['Open fold (za / <leader>ff)'] = function()
    vim.cmd 'normal! za'
  end,
  ['Open all folds folds under the cursor (level fold) (<leader>fl)'] = function()
    vim.cmd 'normal! zazczA'
  end,
  ['Close all folds (<leader>fc)'] = function()
    vim.cmd 'normal! zM'
  end,
  ['Duplicate / Copy number of lines ({count}<leader>cp)'] = function()
    vim.ui.input({ prompt = 'Enter how many lines down: ' }, function(lines_down)
      if not lines_down then
        lines_down = ''
      end
      vim.fn.feedkeys(lines_down .. T '<leader>' .. 'cp')
    end)
  end,
  ['Center Focus (zz)'] = function()
    vim.fn.feedkeys 'zz'
  end,
  ['Bottom Focus (zb)'] = function()
    vim.fn.feedkeys 'zb'
  end,
  ['Top Focus (zt)'] = function()
    vim.fn.feedkeys 'zt'
  end,
  ['Record Macro (q{letter})'] = function()
    vim.ui.input({ prompt = 'Macro letter: ' }, function(macro_letter)
      if not macro_letter then
        macro_letter = 'q'
      end
      vim.fn.feedkeys('q' .. macro_letter)
      pretty_print('Recording macro ' .. macro_letter .. ' (hit q when finished)', 'Macro')
      pretty_print('You can repeat this macro with @' .. macro_letter, 'Macro')
    end)
  end,
  ['Repeat Macro (@{letter} / Q)'] = function()
    vim.ui.input({ prompt = 'Macro letter: ' }, function(macro_letter)
      if not macro_letter then
        macro_letter = 'q'
      end
      vim.ui.input({ prompt = 'Enter how many times (leave blank for once): ' }, function(macro_times)
        if not macro_times then
          macro_times = ''
        end
        vim.fn.feedkeys(macro_times .. '@' .. macro_letter)
      end)
    end)
  end,
  ['Toggle Terminal (<F6>)'] = function()
    vim.cmd.FloatermToggle()
  end,
  ['Create a new terminal window (<F7>)'] = function()
    vim.cmd.FloatermNew()
  end,
  ['Move to next terminal window (<F8>)'] = function()
    vim.cmd.FloatermNext()
  end,
  ['Move to previous terminal window'] = function()
    vim.cmd.FloatermPrev()
  end,
  ['Find files (<C-p>)'] = function()
    require('telescope.builtin').find_files()
  end,
  ['Find buffers (<C-b>)'] = function()
    require('telescope.builtin').buffers()
  end,
  ['Open Nvim Tree File Browser (<C-o>)'] = function()
    local api = require 'nvim-tree.api'
    api.tree.toggle()
  end,
  ['Resize panes (<C-e>)'] = function()
    vim.fn.feedkeys(T '<C-e>')
  end,
  ['Close all notifications (<leader>x)'] = function()
    require('notify').dismiss()
  end,
  ['Quit all (<leader>qq)'] = function()
    vim.cmd.qall()
  end,
  ['Paste from clipboard (cv)'] = function()
    vim.fn.feedkeys 'cv'
  end,
  ['Copy entire file to clipboard (Y)'] = function()
    vim.fn.feedkeys 'Y'
  end,
  ['Convert \\n to new lines (<leader><cr>)'] = function()
    vim.fn.feedkeys(T '<leader>' .. T '<cr>')
  end,
  ['Move line down (-)'] = function()
    vim.fn.feedkeys '-'
  end,
  ['Move line up (_)'] = function()
    vim.fn.feedkeys '_'
  end,
  ['Copy full file path to clipboard (<leader>cfa)'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'cfa')
  end,
  ['Copy relative file path to clipboard (<leader>cfp)'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'cfp')
  end,
  ['Copy directory path to clipboard (<leader>cfd)'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'cfd')
  end,
  ['Copy file name to clipboard (<leader>cfn)'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'cfn')
  end,
  ['Split long bash line (<leader>\\'] = function()
    vim.fn.feedkeys(T '<leader>' .. [[\]])
  end,
  ['Delete all hidden buffers (:BDelete hidden)'] = function()
    vim.cmd 'BDelete hidden'
  end,
  ['Delete current buffer (<leader>bd)'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'bd')
  end,
  ['Yaml to Json (:Yaml2Json)'] = function()
    vim.cmd.Yaml2Json()
  end,
  ['Json to Yaml (:Json2Yaml)'] = function()
    vim.cmd.Json2Yaml()
  end,
  ['Change indent size (<leader>cii)'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'cii')
  end,
  ['Convert tabs to spaces (<leader>ct<SPC>)'] = function()
    local original_expandtab = vim.opt_global.expandtab:get()
    vim.opt.expandtab = true
    vim.cmd.retab()
    vim.opt.expandtab = original_expandtab
  end,
  ['Diff unsaved with saved file (<leader>ds)'] = function()
    vim.fn.feedkeys(T '<leader>' .. 'ds')
  end,
}
