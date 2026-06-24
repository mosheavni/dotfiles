--- Stub vim.notify in tests without tripping duplicate-set-field diagnostics.
---@diagnostic disable: duplicate-set-field
local M = {}

---@class NotifyStub
---@field messages { msg: string, level?: integer, opts?: table }[]
---@field _orig fun(msg: string, level?: integer, opts?: table)

---@return NotifyStub
function M.install()
  local stub = {
    messages = {},
    _orig = vim.notify,
  }
  vim.notify = function(msg, level, opts)
    table.insert(stub.messages, { msg = msg, level = level, opts = opts })
  end
  return stub
end

---@param stub NotifyStub
function M.restore(stub)
  if stub._orig then
    vim.notify = stub._orig
    stub._orig = nil
  end
end

---@param fn fun(messages: { msg: string, level?: integer, opts?: table }[])
function M.with(fn)
  local stub = M.install()
  local ok, err = pcall(fn, stub.messages)
  M.restore(stub)
  if not ok then
    error(err, 0)
  end
end

return M
