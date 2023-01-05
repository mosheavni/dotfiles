local utils = require 'user.utils'
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

return M
