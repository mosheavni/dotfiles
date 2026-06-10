-- Minimal yank ring, no plugins: registers 0-9 hold yank history,
-- <C-n>/<C-m> replace the last put with the next/previous entry.
local M = {}

local MAX = 9

---@class YankRingState
---@field idx integer ring register shown by the last put
---@field buf integer
---@field tick integer changedtick right after the put
---@field regtype string

---@type YankRingState|nil
local state

local function shift_registers()
  for i = MAX, 1, -1 do
    vim.fn.setreg(tostring(i), vim.fn.getreginfo(tostring(i - 1)))
  end
end

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

---@param idx integer
---@param dir 1|-1
---@return integer|nil
local function next_nonempty(idx, dir)
  for _ = 1, MAX do
    idx = ((idx - 1 + dir) % MAX) + 1
    if vim.fn.getreg(tostring(idx)) ~= '' then
      return idx
    end
  end
end

---Replace the last put with another ring entry.
---@param dir 1|-1 1 = older yank, -1 = newer yank
function M.cycle(dir)
  if not state or state.buf ~= vim.api.nvim_get_current_buf() or vim.api.nvim_buf_get_changedtick(0) ~= state.tick then
    return
  end
  local idx = next_nonempty(state.idx, dir)
  if not idx or idx == state.idx then
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
        shift_registers()
      end
    end,
  })
  vim.api.nvim_create_autocmd('TextPutPost', {
    group = group,
    desc = 'Track last put register for ring cycling',
    callback = on_put,
  })
  vim.keymap.set('n', '<c-n>', function()
    M.cycle(-1)
  end, { desc = 'Replace put with next (newer) yank' })
  vim.keymap.set('n', '<c-m>', function()
    M.cycle(1)
  end, { desc = 'Replace put with previous (older) yank' })
  vim.keymap.set('n', '<leader>y', '<cmd>registers 0123456789<cr>', { desc = 'Show yank ring registers' })
end

return M
