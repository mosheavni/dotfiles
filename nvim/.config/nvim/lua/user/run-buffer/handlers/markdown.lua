-- Markdown preview: mdserve on the first free port (multiple previews can run).
local PORT_FIRST = 3000
local PORT_LAST = 3099

local function port_in_use(port)
  local out = vim.fn.system { 'lsof', '-nP', '-iTCP:' .. port, '-sTCP:LISTEN', '-t' }
  return vim.trim(out) ~= ''
end

local function find_free_port()
  for port = PORT_FIRST, PORT_LAST do
    if not port_in_use(port) then
      return port
    end
  end
end

return {
  ft = 'markdown',
  ---@type RunHandler
  handler = {
    resolve = function(ctx)
      local port = find_free_port()
      if not port then
        print(('[run-buffer] markdown: no free port in %d-%d'):format(PORT_FIRST, PORT_LAST))
        return { spawn = false }
      end

      print(('[run-buffer] markdown: starting mdserve on :%d for %s'):format(port, ctx.file_name))

      local job_id = vim.fn.jobstart({
        'mdserve',
        '--hostname',
        '127.0.0.1',
        '--port',
        tostring(port),
        '--open',
        ctx.file_name,
      }, {
        on_exit = function(_, code)
          if code ~= 0 then
            vim.schedule(function()
              print(('[run-buffer] markdown: mdserve on :%d exited (%d)'):format(port, code))
            end)
          end
        end,
      })

      if job_id <= 0 then
        print '[run-buffer] markdown: jobstart failed (is mdserve on PATH?)'
        return { spawn = false }
      end

      print(('[run-buffer] markdown: preview http://127.0.0.1:%d/ (job_id=%d)'):format(port, job_id))
      return { spawn = false }
    end,
  },
}
