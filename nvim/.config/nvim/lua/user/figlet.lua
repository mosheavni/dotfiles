local M = {}

-- Curated fonts; previews assume they exist in figlet's font dir (figlet -I2).
-- sync.sh (figlet section) parses this list and downloads missing ones.
local fonts = {
  '3d',
  'ANSI Regular',
  'ANSI Shadow',
  'Banner3-D',
  'Bright',
  'Calvin S',
  'Cybermedium',
  'DOS Rebel',
  'Double',
  'Electronic',
  'ascii12',
  'ascii9',
  'banner',
  'basic',
  'big',
  'bigmono9',
  'future',
  'halfiwi',
  'kompaktblk',
  'maxiwi',
  'miniwi',
  'pagga',
  'rebel',
  'roman',
  'smmono12',
  'smmono9',
  'smslant',
  'standard',
  'terminus',
}

function M.pick_font()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local width = vim.api.nvim_win_get_width(0)

  require('fzf-lua').fzf_exec(fonts, {
    prompt = 'Figlet Font❯ ',
    preview = string.format('figlet -w %d -f {} "Hello, World"', width),
    actions = {
      ['default'] = function(selected)
        if not (selected and selected[1]) then
          return
        end
        local font = selected[1]
        require('fzf-lua.utils').fzf_exit()
        vim.defer_fn(function()
          vim.ui.input({ prompt = 'Text to figlet❯ ' }, function(text)
            if not text or text == '' then
              return
            end
            local result = vim.system({ 'figlet', '-w', tostring(width), '-f', font, text }):wait()
            if result.code ~= 0 then
              vim.notify('Figlet failed: ' .. (result.stderr or 'unknown error'), vim.log.levels.ERROR)
              return
            end
            local lines = vim.split(result.stdout, '\n', { plain = true })
            if lines[#lines] == '' then
              table.remove(lines)
            end
            vim.api.nvim_buf_set_lines(buf, row, row, false, lines)
          end)
        end, 100)
      end,
    },
  })
end

function M.setup()
  vim.api.nvim_create_user_command('Figlet', M.pick_font, { desc = 'Pick a figlet font and insert ASCII art' })

  require('user.menu').add_actions('Insert', {
    ['Pick figlet font and insert ASCII art (:Figlet)'] = function()
      vim.cmd [[Figlet]]
    end,
  })
end

return M
