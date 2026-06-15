local ns = vim.api.nvim_create_namespace 'search_count_virt'
local clear = function()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

local function update()
  clear()
  local ok, r = pcall(vim.fn.searchcount, { recompute = true, maxcount = 0 })
  if not ok or not r or r.total == 0 or r.incomplete ~= 0 or r.exact_match ~= 1 then
    return
  end
  vim.api.nvim_buf_set_extmark(0, ns, vim.api.nvim_win_get_cursor(0)[1] - 1, -1, {
    virt_text = { { string.format(' %d/%d', r.current, r.total), 'IncSearch' } },
    virt_text_pos = 'eol',
  })
end

local function setup()
  local group = vim.api.nvim_create_augroup('SearchCountVirt', { clear = true })
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    callback = function()
      if vim.v.hlsearch == 1 then
        update()
      else
        clear()
      end
    end,
  })
  vim.api.nvim_create_autocmd('CmdlineLeave', {
    group = group,
    pattern = { '/', '?' },
    callback = function()
      vim.schedule(update)
    end,
  })
  vim.api.nvim_create_autocmd('InsertEnter', { group = group, callback = clear })
end

return { setup = setup, update = update, clear = clear, ns = ns }
