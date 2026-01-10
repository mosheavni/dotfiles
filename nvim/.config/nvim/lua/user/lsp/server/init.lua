-- Custom in-process LSP server for code actions and hover
-- Configuration: lsp/user_lsp.lua

local actions = require 'user.lsp.server.actions'
local hover = require 'user.lsp.server.hover'

local M = {
  id = nil,
  version = '0.1.0',
}

local USER_LSP_COMMAND = 'user_lsp_command'

-- Configuration
M.config = {
  name = 'user-lsp',
  -- Set to specific filetypes like { "lua", "python" } to limit scope
  -- nil means all files
  filetypes = nil,
}

-- Commands for LSP command execution
M.commands = {
  ---@param cmd table
  ---@param _ctx table<string,any>
  [USER_LSP_COMMAND] = function(cmd, _ctx)
    local action = cmd.arguments[1]
    if action then
      action()
    else
      vim.notify('Action not available', vim.log.levels.INFO)
    end
  end,
}

--- Creates an in-process LSP server
---@return function
function M.create_server()
  local capabilities = {
    codeActionProvider = true,
    hoverProvider = true,
    textDocumentSync = {
      openClose = true,
      change = 1, -- TextDocumentSyncKind.Full
    },
  }

  local handlers = {
    ---@param _method string
    ---@param params any
    ---@param callback fun(err: nil, actions: lsp.CodeAction[])
    ['textDocument/codeAction'] = function(_method, params, callback)
      local code_actions = {}
      for _, action in ipairs(actions.get_actions(params)) do
        local ca = {
          title = action.title,
          kind = action.kind or 'source',
        }
        if action.edit then
          ca.edit = action.edit
        elseif action.action then
          ca.command = {
            title = action.title,
            command = USER_LSP_COMMAND,
            arguments = { action.action },
          }
        end
        table.insert(code_actions, ca)
      end
      callback(nil, code_actions)
    end,

    ---@param _method string
    ---@param params any
    ---@param callback fun(err: nil, hover: lsp.Hover|nil)
    ['textDocument/hover'] = function(_method, params, callback)
      local result = hover.get_hover(params)
      callback(nil, result)
    end,
  }

  return function(dispatchers)
    local closing = false
    local srv = {}
    local request_id = 0

    function srv.request(method, params, callback, notify_reply_callback)
      local handler = handlers[method]
      if handler then
        handler(method, params, callback)
      elseif method == 'initialize' then
        callback(nil, {
          capabilities = capabilities,
          serverInfo = {
            name = M.config.name,
            version = M.version,
          },
        })
      elseif method == 'shutdown' then
        callback(nil, nil)
      end
      request_id = request_id + 1
      if notify_reply_callback then
        notify_reply_callback(request_id)
      end
      return true, request_id
    end

    function srv.notify(method, _params)
      if method == 'exit' then
        dispatchers.on_exit(0, 15)
      end
    end

    function srv.is_closing()
      return closing
    end

    function srv.terminate()
      closing = true
    end

    return srv
  end
end

return M
