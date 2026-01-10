-- Custom in-process LSP server for code actions and hover
-- Based on crates.nvim's LSP implementation pattern

local actions = require 'user.lsp.server.actions'
local hover = require 'user.lsp.server.hover'

local M = {
  id = nil,
}

-- Configuration
M.config = {
  name = 'user-lsp',
  -- Set to specific filetypes like { "lua", "python" } to limit scope
  -- nil means all files
  filetypes = nil,
}

---@class ServerOpts
---@field capabilities table
---@field handlers table<string,fun(method: string, params: any, callback: function)>

--- Creates an in-process LSP server
---@param opts ServerOpts
---@return function
local function create_server(opts)
  opts = opts or {}
  local capabilities = opts.capabilities or {}
  local handlers = opts.handlers or {}

  return function(dispatchers)
    local closing = false
    local srv = {}
    local request_id = 0

    ---@param method string
    ---@param params any
    ---@param callback fun(error: any?, data: any?)
    ---@param notify_reply_callback? fun(request_id: integer)
    ---@return boolean
    ---@return integer
    function srv.request(method, params, callback, notify_reply_callback)
      local handler = handlers[method]
      if handler then
        handler(method, params, callback)
      elseif method == 'initialize' then
        callback(nil, {
          capabilities = capabilities,
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

    ---@param method string
    ---@param _params any
    function srv.notify(method, _params)
      if method == 'exit' then
        dispatchers.on_exit(0, 15)
      end
    end

    ---@return boolean
    function srv.is_closing()
      return closing
    end

    function srv.terminate()
      closing = true
    end

    return srv
  end
end

-- Reuse client by name instead of root_dir
---@param client vim.lsp.Client
---@param config vim.lsp.ClientConfig
---@return boolean
local function reuse_client(client, config)
  return client.name == config.name
end

--- Start the custom LSP server
function M.start()
  local USER_LSP_COMMAND = 'user_lsp_command'

  local commands = {
    ---@param cmd table
    ---@param ctx table<string,any>
    [USER_LSP_COMMAND] = function(cmd, ctx)
      local action = cmd.arguments[1]
      if action then
        vim.api.nvim_buf_call(ctx.bufnr, action)
      else
        vim.notify('Action not available', vim.log.levels.INFO)
      end
    end,
  }

  local server = create_server {
    capabilities = {
      codeActionProvider = true,
      hoverProvider = true,
    },
    handlers = {
      ---@param _method string
      ---@param params any
      ---@param callback fun(err: nil, actions: lsp.CodeAction[])
      ['textDocument/codeAction'] = function(_method, params, callback)
        local code_actions = {}
        for _, action in ipairs(actions.get_actions(params)) do
          table.insert(code_actions, {
            title = action.title,
            kind = action.kind or 'source',
            command = {
              title = action.title,
              command = USER_LSP_COMMAND,
              arguments = { action.action },
            },
          })
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
    },
  }

  local buf = vim.api.nvim_get_current_buf()

  local client_id = vim.lsp.start({
    name = M.config.name,
    cmd = server,
    commands = commands,
  }, {
    bufnr = buf,
    reuse_client = reuse_client,
  })

  if client_id then
    M.id = client_id
  end
end

--- Setup function to auto-start the server
function M.setup()
  local pattern = M.config.filetypes or '*'
  vim.api.nvim_create_autocmd('FileType', {
    pattern = pattern,
    group = vim.api.nvim_create_augroup('UserLspServer', { clear = true }),
    callback = function()
      M.start()
    end,
  })
end

return M
