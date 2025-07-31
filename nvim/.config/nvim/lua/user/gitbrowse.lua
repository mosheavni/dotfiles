---@class user.gitbrowse
---@overload fun(opts?: user.gitbrowse.Config)
local M = setmetatable({}, {
  __call = function(t, ...)
    return t.open(...)
  end,
})

M.meta = {
  desc = 'Open the current file, branch, commit, or repo in a browser (e.g. GitHub, GitLab, Bitbucket)',
}

local uv = vim.uv or vim.loop

---@class user.gitbrowse.Config
---@field url_patterns? table<string, table<string, string|fun(fields:user.gitbrowse.Fields):string>>
local defaults = {
  notify = true, -- show notification on open
  -- Handler to open the url in a browser
  ---@param url string
  open = function(url)
    vim.ui.open(url)
  end,
  ---@type "repo" | "branch" | "file" | "commit"
  what = 'file', -- what to open. not all remotes support all types
  branch = nil, ---@type string?
  commit = nil, ---@type string?
  line_start = nil, ---@type number?
  line_end = nil, ---@type number?
  -- patterns to transform remotes to an actual URL
  -- stylua: ignore
  remote_patterns = {
    { "^(https?://.*)%.git$"              , "%1" },
    { "^git@(.+):(.+)%.git$"              , "https://%1/%2" },
    { "^git@(.+):(.+)$"                   , "https://%1/%2" },
    { "^git@(.+)/(.+)$"                   , "https://%1/%2" },
    { "^ssh://git@(.*)$"                  , "https://%1" },
    { "^ssh://([^:/]+)(:%d+)/(.*)$"       , "https://%1/%3" },
    { "^ssh://([^/]+)/(.*)$"              , "https://%1/%2" },
    { "ssh%.dev%.azure%.com/v3/(.*)/(.*)$", "dev.azure.com/%1/_git/%2" },
    { "^https://%w*@(.*)"                 , "https://%1" },
    { "^git@(.*)"                         , "https://%1" },
    { ":%d+"                              , "" },
    { "%.git$"                            , "" },
  },
  url_patterns = {
    ['github%.com'] = {
      branch = '/tree/{branch}',
      file = '/blob/{branch}/{file}#L{line_start}-L{line_end}',
      commit = '/commit/{commit}',
    },
    ['gitlab%.com'] = {
      branch = '/-/tree/{branch}',
      file = '/-/blob/{branch}/{file}#L{line_start}-L{line_end}',
      commit = '/-/commit/{commit}',
    },
    ['bitbucket%.org'] = {
      branch = '/src/{branch}',
      file = '/src/{branch}/{file}#lines-{line_start}-L{line_end}',
      commit = '/commits/{commit}',
    },
  },
}

---@class user.gitbrowse.Fields
---@field branch? string
---@field file? string
---@field line_start? number
---@field line_end? number
---@field commit? string
---@field line_count? number

---@private
---@param remote string
---@param opts? user.gitbrowse.Config
function M.get_repo(remote, opts)
  opts = vim.tbl_deep_extend('force', defaults, opts or {})
  local ret = remote
  for _, pattern in ipairs(opts.remote_patterns) do
    ret = ret:gsub(pattern[1], pattern[2]) --[[@as string]]
  end
  return ret:find 'https://' == 1 and ret or ('https://%s'):format(ret)
end

---@param repo string
---@param fields user.gitbrowse.Fields
---@param opts? user.gitbrowse.Config
function M.get_url(repo, fields, opts)
  opts = vim.tbl_deep_extend('force', defaults, opts or {})
  for remote, patterns in pairs(opts.url_patterns) do
    if repo:find(remote) then
      local pattern = patterns[opts.what]
      if type(pattern) == 'string' then
        return repo .. pattern:gsub('(%b{})', function(key)
          return fields[key:sub(2, -2)] or key
        end)
      elseif type(pattern) == 'function' then
        return repo .. pattern(fields)
      end
    end
  end
  return repo
end

---@param cmd string[]
---@param err string
local function system(cmd, err)
  local proc = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify { err, proc }
    error '__ignore__'
  end
  return vim.split(vim.trim(proc), '\n')
end

---@param hash string
---@param cwd string
---@return boolean
local function is_valid_commit_hash(hash, cwd)
  if not (hash:match '^[a-fA-F0-9]+$' and #hash >= 7) then
    return false
  end
  system({ 'git', '-C', cwd, 'rev-parse', '--verify', hash }, 'Invalid commit hash')
  return true
end

---@param opts? user.gitbrowse.Config
function M.open(opts)
  opts = vim.tbl_deep_extend('force', defaults, opts or {})
  local ok, err = pcall(M._open, opts) -- errors are handled with notifications
  if not ok and err ~= '__ignore__' then
    error(err)
  end
end

---@param opts? user.gitbrowse.Config
function M._open(opts)
  opts = vim.tbl_deep_extend('force', defaults, opts or {})
  local file = vim.api.nvim_buf_get_name(0) ---@type string?
  file = file and (uv.fs_stat(file) or {}).type == 'file' and vim.fs.normalize(file) or nil
  local cwd = file and vim.fn.fnamemodify(file, ':h') or vim.fn.getcwd()
  local word = vim.fn.expand '<cword>'
  local commit_to_check = opts.commit or word
  local is_commit = commit_to_check and is_valid_commit_hash(commit_to_check, cwd)

  ---@type user.gitbrowse.Fields
  local fields = {
    branch = opts.branch or system({ 'git', '-C', cwd, 'rev-parse', 'HEAD' }, 'Failed to get current branch')[1],
    file = file and system({ 'git', '-C', cwd, 'ls-files', '--full-name', file }, 'Failed to get git file path')[1],
    line_start = opts.line_start,
    line_end = opts.line_end,
    commit = is_commit and commit_to_check or nil,
  }

  -- Get visual selection range if in visual mode
  if vim.fn.mode():find '[vV]' then
    vim.fn.feedkeys(':', 'nx')
    local line_start = vim.api.nvim_buf_get_mark(0, '<')[1]
    local line_end = vim.api.nvim_buf_get_mark(0, '>')[1]
    vim.fn.feedkeys('gv', 'nx')
    -- Ensure line_start is always the smaller number
    if line_start > line_end then
      line_start, line_end = line_end, line_start
    end
    fields.line_start = line_start
    fields.line_end = line_end
  else
    fields.line_start = fields.line_start or vim.fn.line '.'
    fields.line_end = fields.line_end or fields.line_start
  end
  fields.line_count = fields.line_end - fields.line_start + 1

  opts.what = is_commit and 'commit' or opts.what == 'commit' and not fields.commit and 'file' or opts.what
  opts.what = not is_commit and opts.what == 'file' and not fields.file and 'branch' or opts.what
  opts.what = not is_commit and opts.what == 'branch' and not fields.branch and 'repo' or opts.what

  local remotes = {} ---@type {name:string, url:string}[]

  for _, line in ipairs(system({ 'git', '-C', cwd, 'remote', '-v' }, 'Failed to get git remotes')) do
    local name, remote = line:match '(%S+)%s+(%S+)%s+%(fetch%)'
    if name and remote then
      local repo = M.get_repo(remote, opts)
      if repo then
        table.insert(remotes, {
          name = name,
          url = M.get_url(repo, fields, opts),
        })
      end
    end
  end

  local function open(remote)
    if remote then
      if opts.notify ~= false then
        vim.notify(('Opening [%s](%s)'):format(remote.name, remote.url))
      end
      opts.open(remote.url)
    end
  end

  if #remotes == 0 then
    return vim.notify 'No git remotes found'
  elseif #remotes == 1 then
    return open(remotes[1])
  end

  vim.ui.select(remotes, {
    prompt = 'Select remote to browse',
    title = 'Git remotes',
    format_item = function(item)
      return item.name .. (' '):rep(8 - #item.name) .. ' 🔗 ' .. item.url
    end,
  }, open)
end

return M
