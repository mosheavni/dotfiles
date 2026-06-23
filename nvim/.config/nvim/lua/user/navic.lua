local core = require 'user.navic_core'

local M = {}
local cache = {} -- [bufnr] = { symbols, location }
local awaiting_lsp_response = {}

local function update(buf)
  local data = cache[buf]
  if not data or not data.symbols then
    return
  end
  local ok, cursor = pcall(vim.api.nvim_win_get_cursor, 0)
  if not ok then
    return
  end
  local parts = core.find_in_symbols(data.symbols, cursor[1] - 1, cursor[2])
  data.location = table.concat(parts, core.separator)
end

function M.get_location()
  local buf = vim.api.nvim_get_current_buf()
  local data = cache[buf]
  if not data or not data.location or data.location == '' then
    return ''
  end
  return data.location
end

function M.setup()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserNavic', { clear = true }),
    callback = function(ev)
      local bufnr = ev.buf
      if vim.b[bufnr].navic_client_id ~= nil then
        return
      end

      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client or not client:supports_method 'textDocument/documentSymbol' then
        return
      end

      vim.b[bufnr].navic_client_id = client.id
      cache[bufnr] = cache[bufnr] or {}
      local changedtick = 0

      local function fetch(retry_count)
        retry_count = retry_count or 10
        if not vim.api.nvim_buf_is_loaded(bufnr) then
          awaiting_lsp_response[bufnr] = false
          return
        end

        awaiting_lsp_response[bufnr] = true
        client:request('textDocument/documentSymbol', {
          textDocument = vim.lsp.util.make_text_document_params(bufnr),
        }, function(err, result)
          awaiting_lsp_response[bufnr] = false
          if err ~= nil then
            if retry_count > 0 and vim.api.nvim_buf_is_valid(bufnr) then
              vim.defer_fn(function()
                fetch(retry_count - 1)
              end, 750)
            end
            return
          end

          cache[bufnr] = cache[bufnr] or {}
          cache[bufnr].symbols = result or {}
          update(bufnr)
        end, bufnr)
      end

      local function maybe_fetch()
        if awaiting_lsp_response[bufnr] then
          return
        end
        if changedtick < vim.b[bufnr].changedtick then
          changedtick = vim.b[bufnr].changedtick
          fetch()
        end
      end

      fetch()

      local navic_buf_group = vim.api.nvim_create_augroup('UserNavicBuf' .. bufnr, { clear = true })
      vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufEnter', 'CursorHold', 'BufWritePost' }, {
        group = navic_buf_group,
        buffer = bufnr,
        callback = maybe_fetch,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        group = navic_buf_group,
        buffer = bufnr,
        callback = function()
          update(bufnr)
        end,
      })
      vim.api.nvim_create_autocmd('BufDelete', {
        group = navic_buf_group,
        buffer = bufnr,
        once = true,
        callback = function()
          cache[bufnr] = nil
          awaiting_lsp_response[bufnr] = nil
          vim.b[bufnr].navic_client_id = nil
        end,
      })
    end,
  })

  vim.o.winbar = "%{%v:lua.require'user.navic'.get_location()%}"
end

return M
