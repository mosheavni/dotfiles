local utils = require 'user.utils'
local pretty_print = utils.pretty_print
local find_in_project = function(bang)
  vim.ui.input({ prompt = 'Enter search term (blank for word under cursor): ' }, function(search_term)
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

local M = {}

M.pretty_print = function(message)
  utils.pretty_print(message, 'Git Actions', '')
end

M.dap = function()
  local dap = require 'dap'
  return {
    ['continue'] = function()
      dap.continue()
    end,
    ['step over'] = function()
      dap.step_over()
    end,
    ['step into'] = function()
      dap.step_into()
    end,
    ['step out'] = function()
      dap.step_out()
    end,
    ['toggle breakpoint'] = function()
      dap.toggle_breakpoint()
    end,
    ['clear all breakpoints'] = function()
      dap.clear_breakpoints()
    end,
    ['open repl'] = function()
      dap.repl.open()
    end,
    ['run last'] = function()
      dap.run_last()
    end,
    ['ui'] = function()
      dapui.toggle()
    end,
    ['log level trace'] = function()
      dap.set_log_level 'TRACE'
      vim.cmd 'DapShowLog'
    end,
  }
end

M.git = {
  ['Change branch'] = function()
    require('user.git-branches').open()
  end,
  ['Checkout new branch'] = function()
    new_branch { args = '' }
  end,
  ['Work in Progress commit'] = function()
    vim.cmd 'call Enter_Wip_Moshe()'
    M.pretty_print 'Created a work in progress commit.'
  end,
  ['Diff File History'] = function()
    vim.ui.input({ prompt = 'Enter file path (empty for current file): ' }, function(file_to_check)
      if file_to_check == '' then
        file_to_check = '%'
      end

      vim.cmd('DiffviewFileHistory ' .. file_to_check)
    end)
  end,
  ['Diff with branch'] = function()
    vim.ui.input({ prompt = 'Enter branch to diff with: ' }, function(branch_to_diff)
      if not branch_to_diff then
        M.pretty_print 'Canceled.'
        return
      end
      vim.cmd('DiffviewOpen ' .. branch_to_diff)
    end)
  end,
  ['Diff close'] = function()
    vim.cmd 'DiffviewClose'
  end,
  ['Blame'] = function()
    vim.cmd 'G blame'
  end,
  ['Pull origin master'] = function()
    vim.cmd 'Gpom'
    M.pretty_print 'Pulled from origin master.'
  end,
  ['Pull origin {branch}'] = function()
    vim.ui.input({ prompt = 'Enter branch to pull from: ' }, function(branch_to_pull)
      if not branch_to_pull then
        M.pretty_print 'Canceled.'
        return
      end
      vim.cmd('G pull origin ' .. branch_to_pull)
      M.pretty_print('Pulled from origin ' .. branch_to_pull)
    end)
  end,
  ['Merge origin/master'] = function()
    vim.cmd 'Gmom'
    M.pretty_print 'Merged with origin/master. (might need to fetch new commits)'
  end,
  ['Status'] = function()
    vim.cmd 'Git'
  end,
  ['Open GitHub on this line'] = function()
    vim.cmd 'ToGithub'
  end,
  ['Log'] = function()
    vim.cmd 'G log --all --decorate --oneline'
  end,
  ['See all tags'] = function()
    local tags = vim.fn.FugitiveExecute('tag').stdout
    vim.ui.select(tags, { prompt = 'Select tag to copy to clipboard' }, function(selection)
      if not selection then
        M.pretty_print 'Canceled.'
        return
      end
      vim.fn.setreg('+', selection)
      M.pretty_print('Copied ' .. selection .. ' to clipboard.')
    end)
  end,
  ['Create tag'] = function()
    vim.ui.input({ prompt = 'Enter tag name: ' }, function(input)
      if not input then
        M.pretty_print 'Canceled.'
        return
      end
      vim.cmd('G tag ' .. input)
      vim.ui.select({ 'Yes', 'No' }, { prompt = 'Push?' }, function(choice)
        if choice == 'Yes' then
          vim.cmd 'G push --tags'
          M.pretty_print('Tag ' .. input .. ' created and pushed.')
        else
          M.pretty_print('Tag ' .. input .. ' created.')
        end
      end)
    end)
  end,
  ['Delete tag'] = function()
    local tags = vim.fn.FugitiveExecute('tag').stdout

    vim.ui.select(tags, { prompt = 'Enter tag name' }, function(input)
      if not input then
        M.pretty_print 'Canceled.'
        return
      end
      vim.cmd('G tag -d ' .. input)
      vim.ui.select({ 'Yes', 'No' }, { prompt = 'Remove from remote?' }, function(choice)
        if choice == 'Yes' then
          vim.cmd 'G push --tags'
          if not vim.g.default_branch then
            M.pretty_print 'default_branch is not set'
            return
          end
          vim.cmd('G push origin ' .. vim.g.default_branch .. ' :refs/tags/' .. input)
          M.pretty_print('Tag ' .. input .. ' deleted from local and remote.')
        else
          M.pretty_print('Tag ' .. input .. ' deleted locally.')
        end
      end)
    end)
  end,
  ['Find in all commits'] = function()
    local rev_list = vim.fn.FugitiveExecute({ 'rev-list', '--all' }).stdout
    vim.ui.input({ prompt = 'Enter search term: ' }, function(search_term)
      if not search_term then
        M.pretty_print 'Canceled.'
        return
      end
      M.pretty_print('Searching for ' .. search_term .. ' in all commits...')
      vim.cmd('silent Ggrep  ' .. vim.fn.fnameescape(search_term) .. ' ' .. table.concat(rev_list, ' '))
    end)
  end,
  ['Push'] = function()
    vim.cmd 'Gp'
  end,
  ['Pull'] = function()
    vim.cmd 'Gl'
  end,
  ['Add (Stage) All'] = function()
    vim.cmd 'G add -A'
  end,

  ['Unstage All'] = function()
    vim.cmd 'G reset'
  end,
}

M.lsp = {
  ['Format'] = function()
    require('user.lsp.formatting').format()
  end,
  ['Code Actions'] = function()
    vim.lsp.buf.code_action()
  end,
  ['Code Lens'] = function()
    vim.lsp.codelens.run()
  end,
  ['Show Definition'] = function()
    vim.cmd 'Lspsaga peek_definition'
  end,
  ['Show Declaration'] = function()
    vim.lsp.buf.declaration()
  end,

  ['Show Type Definition'] = function()
    vim.lsp.buf.type_definition()
  end,
  ['Show Implementation'] = function()
    vim.lsp.buf.implementation()
  end,
  ['Find References'] = function()
    vim.cmd 'Lspsaga lsp_finder'
  end,
  ['Signature Help'] = function()
    vim.lsp.buf.signature_help()
  end,
  ['Signature Documentation'] = function()
    vim.lsp.buf.hover()
  end,
  ['Diagnostics quickfix list'] = function()
    vim.diagnostic.setqflist()
  end,
}

M.random = {
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
    vim.cmd [[normal! ggVG]]
  end,
  ['Indent block forward'] = function()
    vim.cmd [[normal! v%koj$>]]
  end,
  ['Open all folds'] = function()
    vim.cmd 'normal! zR'
  end,
  ['Open fold'] = function()
    vim.cmd 'normal! za'
  end,
  ['Open all folds folds under the cursor (level fold)'] = function()
    vim.cmd 'normal! zazczA'
  end,
  ['Close all folds'] = function()
    vim.cmd 'normal! zM'
  end,
  ['Duplicate / Copy number of lines'] = function()
    vim.ui.input({ prompt = 'Enter how many lines down: ' }, function(lines_down)
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
    vim.ui.input({ prompt = 'Macro letter: ' }, function(macro_letter)
      if not macro_letter then
        macro_letter = 'q'
      end
      vim.fn.feedkeys('q' .. macro_letter)
      pretty_print('Recording macro ' .. macro_letter .. ' (hit q when finished)', 'Macro')
      pretty_print('You can repeat this macro with @' .. macro_letter, 'Macro')
    end)
  end,

  ['Repeat Macro'] = function()
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
  ['Toggle Terminal'] = function()
    vim.cmd.FloatermToggle()
  end,
  ['Create a new terminal window'] = function()
    vim.cmd.FloatermNew()
  end,
  ['Move to next terminal window'] = function()
    vim.cmd.FloatermNext()
  end,
  ['Move to previous terminal window'] = function()
    vim.cmd.FloatermPrev()
  end,
  ['Find files'] = function()
    require('telescope.builtin').find_files()
  end,
  ['Find buffers'] = function()
    require('telescope.builtin').buffers()
  end,
  ['Open Nvim Tree File Browser'] = function()
    api.tree.toggle()
  end,
  ['Close all notifications'] = function()
    require('notify').dismiss()
  end,
  ['Quit all'] = function()
    vim.cmd.qall()
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

return M
