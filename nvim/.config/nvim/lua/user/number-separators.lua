local M = {}

local ns_id = vim.api.nvim_create_namespace 'number_separators'

---Format a number string with comma separators
---@param number_str string The number as a string
---@return string The formatted number with commas
function M.format_number(number_str)
  local sign = ''
  if number_str:sub(1, 1) == '-' then
    sign = '-'
    number_str = number_str:sub(2)
  end

  local int_part, dec_part = number_str:match '^(%d*)(%.?%d*)$'
  if not int_part then
    return sign .. number_str
  end

  local formatted = int_part:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')

  return sign .. formatted .. dec_part
end

-- Insert/replace/select modes should not render formatting: the
-- virtual text would interfere with what the user is typing.
local function in_editing_mode()
  local mode = vim.fn.mode()
  local first = mode:sub(1, 1)
  return first == 'i' or first == 'R' or first == 's'
end

local function apply_number_formatting(bufnr)
  bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  if in_editing_mode() then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for lnum, line in ipairs(lines) do
    local search_from = 1
    -- Require a digit after the decimal point so we don't match "1234."
    for number in line:gmatch '%-?%d+%.?%d*' do
      local s, e = line:find(number, search_from, true)
      if s then
        search_from = e + 1
        local formatted = M.format_number(number)
        if formatted ~= number then
          pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, lnum - 1, s - 1, {
            end_col = e,
            virt_text = { { formatted, 'Comment' } },
            virt_text_pos = 'inline',
            conceal = '',
          })
        end
      end
    end
  end
end

local number_separator_group = vim.api.nvim_create_augroup('NumberSeparator', { clear = true })

local function save_and_set_conceal()
  vim.b.number_separators_orig_conceallevel = vim.wo.conceallevel
  vim.b.number_separators_orig_concealcursor = vim.wo.concealcursor
  vim.wo.conceallevel = 2
  vim.wo.concealcursor = 'nc'
end

local function restore_conceal()
  if vim.b.number_separators_orig_conceallevel ~= nil then
    vim.wo.conceallevel = vim.b.number_separators_orig_conceallevel
    vim.b.number_separators_orig_conceallevel = nil
  end
  if vim.b.number_separators_orig_concealcursor ~= nil then
    vim.wo.concealcursor = vim.b.number_separators_orig_concealcursor
    vim.b.number_separators_orig_concealcursor = nil
  end
end

local function enable_number_separators()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.b[bufnr].number_separators_enabled then
    return
  end

  -- Remove any stale autocmds for this buffer before adding new ones.
  vim.api.nvim_clear_autocmds { group = number_separator_group, buffer = bufnr }

  vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'InsertLeave' }, {
    group = number_separator_group,
    buffer = bufnr,
    callback = function(args)
      apply_number_formatting(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd('InsertEnter', {
    group = number_separator_group,
    buffer = bufnr,
    callback = function(args)
      vim.api.nvim_buf_clear_namespace(args.buf, ns_id, 0, -1)
    end,
  })

  save_and_set_conceal()
  vim.b[bufnr].number_separators_enabled = true
  apply_number_formatting(bufnr)
end

local function disable_number_separators()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_clear_autocmds { group = number_separator_group, buffer = bufnr }
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  restore_conceal()
  vim.b[bufnr].number_separators_enabled = false
end

function M.setup()
  vim.api.nvim_create_user_command('NumberSeparatorsToggle', function()
    if vim.b.number_separators_enabled then
      disable_number_separators()
      vim.notify 'Number separators disabled'
    else
      enable_number_separators()
      vim.notify 'Number separators enabled'
    end
  end, {})

  require('user.menu').add_actions('Editor', {
    ['Toggle number separators (:NumberSeparatorsToggle)'] = function()
      vim.cmd [[NumberSeparatorsToggle]]
    end,
  })
end

return M
