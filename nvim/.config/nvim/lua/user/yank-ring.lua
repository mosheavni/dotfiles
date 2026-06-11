-- Minimal yank ring, no plugins: registers 1-9 hold yank history (1 = newest),
-- <C-n>/<C-m> replace the last put with the previous/next entry. No wrapping.
local M = {}

local MAX = 9

---@type { idx: integer, buf: integer, tick: integer, regtype: string }|nil
local state

local function on_put()
  local e = vim.v.event
  local idx
  if e.regname == '' or e.regname == '0' then
    idx = 1
  elseif e.regname:match '^[1-9]$' then
    idx = tonumber(e.regname)
  else
    state = nil
    return
  end
  state = {
    idx = idx,
    buf = vim.api.nvim_get_current_buf(),
    tick = vim.api.nvim_buf_get_changedtick(0),
    regtype = e.regtype,
  }
end

---Replace the last put with the adjacent ring entry.
---@param dir 1|-1 1 = older yank, -1 = newer yank
function M.cycle(dir)
  if not state or state.buf ~= vim.api.nvim_get_current_buf() or vim.api.nvim_buf_get_changedtick(0) ~= state.tick then
    return
  end
  local idx = state.idx + dir
  if idx < 1 or idx > MAX or vim.fn.getreg(tostring(idx)) == '' then
    vim.notify(dir == 1 and 'No older yanks' or 'No newer yanks', vim.log.levels.INFO)
    return
  end
  local vmode = state.regtype == 'V' and 'V' or state.regtype:sub(1, 1) == '\22' and '\22' or 'v'
  -- `[ and `] still frame the last put (changedtick guard above); select the region
  -- and put the target register over it. v_P keeps all registers untouched (:h v_P)
  -- and fires TextPutPost, which re-records state (regname = idx) for the next cycle.
  vim.cmd(('normal! `[%s`]"%dP'):format(vmode, idx))
  -- make a following plain `p` repeat what is now visible
  vim.fn.setreg('"', vim.fn.getreginfo(tostring(idx)))
end

function M.setup()
  local group = vim.api.nvim_create_augroup('UserYankRing', { clear = true })
  vim.api.nvim_create_autocmd('TextYankPost', {
    group = group,
    desc = 'Shift yank history into registers 1-9',
    callback = function()
      local e = vim.v.event
      if e.operator == 'y' and e.regname == '' then
        for i = MAX, 1, -1 do
          vim.fn.setreg(tostring(i), vim.fn.getreginfo(tostring(i - 1)))
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd('TextPutPost', {
    group = group,
    desc = 'Track last put register for ring cycling',
    callback = on_put,
  })
  vim.keymap.set('n', '<c-m>', function()
    M.cycle(-1)
  end, { desc = 'Replace put with newer yank' })
  vim.keymap.set('n', '<c-n>', function()
    M.cycle(1)
  end, { desc = 'Replace put with older yank' })
  vim.keymap.set('n', '<leader>y', '<cmd>registers 0123456789<cr>', { desc = 'Show yank ring registers' })
end

return M
