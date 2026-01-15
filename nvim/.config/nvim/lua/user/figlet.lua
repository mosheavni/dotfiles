local M = {}

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

local font_extensions = { 'flf', 'flc', 'tlf' }
local font_repo_url = 'https://raw.githubusercontent.com/xero/figlet-fonts/master'

local function get_font_dir()
  local result = vim.system({ 'figlet', '-I2' }):wait()
  if result.code == 0 then
    return vim.trim(result.stdout)
  end
  return nil
end

local function font_exists(font_dir, font_name)
  for _, ext in ipairs(font_extensions) do
    local path = vim.fs.joinpath(font_dir, font_name .. '.' .. ext)
    if vim.uv.fs_stat(path) then
      return true, path
    end
  end
  return false, nil
end

local function download_font(font_name, font_dir, callback)
  local try_download
  local ext_index = 1

  try_download = function()
    if ext_index > #font_extensions then
      callback(false)
      return
    end

    local ext = font_extensions[ext_index]
    local url = font_repo_url .. '/' .. vim.uri_encode(font_name, 'rfc2396') .. '.' .. ext
    local dest = vim.fs.joinpath(font_dir, font_name .. '.' .. ext)

    vim.system({ 'curl', '-fsSL', '-o', dest, url }, {}, function(result)
      vim.schedule(function()
        if result.code == 0 then
          vim.notify('Downloaded font: ' .. font_name, vim.log.levels.INFO)
          callback(true)
        else
          -- Remove failed download attempt
          vim.fs.rm(dest, { force = true })
          ext_index = ext_index + 1
          try_download()
        end
      end)
    end)
  end

  try_download()
end

local function ensure_all_fonts(callback)
  local font_dir = get_font_dir()
  if not font_dir then
    vim.notify('Could not determine figlet font directory', vim.log.levels.ERROR)
    callback()
    return
  end

  local missing_fonts = {}
  for _, font_name in ipairs(fonts) do
    if not font_exists(font_dir, font_name) then
      table.insert(missing_fonts, font_name)
    end
  end

  if #missing_fonts == 0 then
    callback()
    return
  end

  vim.notify('Downloading ' .. #missing_fonts .. ' missing font(s)...', vim.log.levels.INFO)

  local pending = #missing_fonts
  for _, font_name in ipairs(missing_fonts) do
    download_font(font_name, font_dir, function()
      pending = pending - 1
      if pending == 0 then
        callback()
      end
    end)
  end
end

local function open_picker(buf, row, width)
  local fzf = require 'fzf-lua'

  fzf.fzf_exec(fonts, {
    prompt = 'Figlet Font❯ ',
    preview = string.format('figlet -w %d -f {} "Hello, World"', width),
    actions = {
      ['default'] = function(selected)
        if selected and selected[1] then
          local font = selected[1]
          vim.defer_fn(function()
            vim.ui.input({ prompt = 'Text to figlet❯ ' }, function(text)
              if text and text ~= '' then
                local result = vim.system({ 'figlet', '-w', tostring(width), '-f', font, text }):wait()
                if result.code == 0 then
                  local lines = vim.split(result.stdout, '\n', { plain = true })
                  -- Remove trailing empty line if present
                  if lines[#lines] == '' then
                    table.remove(lines)
                  end
                  vim.api.nvim_buf_set_lines(buf, row, row, false, lines)
                else
                  vim.notify('Figlet failed: ' .. (result.stderr or 'unknown error'), vim.log.levels.ERROR)
                end
              end
            end)
          end, 1)
        end
      end,
    },
  })
end

function M.pick_font()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local width = vim.api.nvim_win_get_width(0)

  ensure_all_fonts(function()
    open_picker(buf, row, width)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command('Figlet', M.pick_font, { desc = 'Pick a figlet font and insert ASCII art' })
end

return M
