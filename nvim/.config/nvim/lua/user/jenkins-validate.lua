local namespace_id = vim.api.nvim_create_namespace 'jenkinsfile-linter'
local op_jenkins_id = vim.env.OP_JENKINS_ID or 't5ejcfcrjyo243irr2bjy3yqhm'

local creds = nil

local function get_env_creds()
  local user = vim.env.JENKINS_USER_ID or vim.env.JENKINS_USERNAME
  local secret = vim.env.JENKINS_API_TOKEN or vim.env.JENKINS_TOKEN or vim.env.JENKINS_PASSWORD
  local url = vim.env.JENKINS_URL or vim.env.JENKINS_HOST
  if user and secret and url then
    return { user = user, secret = secret, url = url }
  end
end

local function get_onepass_creds()
  if vim.fn.executable 'op' ~= 1 then
    return nil, '1Password CLI not installed (brew install 1password-cli)'
  end
  local res = vim.system({ 'op', 'item', 'get', op_jenkins_id, '--reveal', '--format', 'json' }):wait()
  if res.code ~= 0 then
    return nil, 'op failed: ' .. (res.stderr or 'unknown error')
  end
  local ok, data = pcall(vim.json.decode, res.stdout)
  if not ok then
    return nil, 'failed to parse op output'
  end
  local user, password
  for _, field in ipairs(data.fields or {}) do
    if field.purpose == 'USERNAME' then
      user = field.value
    end
    if field.purpose == 'PASSWORD' then
      password = field.value
    end
  end
  local url = data.urls and data.urls[1] and data.urls[1].href
  if user and password and url then
    return { user = user, secret = password, url = url }
  end
  return nil, 'incomplete credentials in 1Password item'
end

local function get_creds()
  if creds then
    return creds
  end
  creds = get_env_creds()
  if creds then
    return creds
  end
  local op_creds, err = get_onepass_creds()
  if op_creds then
    creds = op_creds
    return creds
  end
  return nil,
    err or [[no credentials found. Set env vars:
  JENKINS_USER_ID, JENKINS_API_TOKEN, JENKINS_URL

To generate a token: Jenkins → Your Name → Security → API Token → Add new Token]]
end

local function get_crumb()
  local c = get_creds()
  local res = vim
    .system({
      'curl',
      '-s',
      '--user',
      c.user .. ':' .. c.secret,
      c.url .. '/crumbIssuer/api/json',
    }, { text = true })
    :wait()
  local ok, data = pcall(vim.json.decode, res.stdout)
  if ok and data.crumb then
    return data.crumb
  end
  return nil, 'failed to get crumb: ' .. (res.stdout or res.stderr or 'unknown')
end

local function parse_error(output)
  local msg, line, col = output:match 'WorkflowScript.+%d+: (.+) @ line (%d+), column (%d+).'
  if line and col then
    return { msg = msg, line = tonumber(line) - 1, col = tonumber(col) - 1 }
  end
end

local function validate()
  local c, err = get_creds()
  if not c then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local crumb, crumb_err = get_crumb()
  if not crumb then
    vim.notify(crumb_err, vim.log.levels.ERROR)
    return
  end

  local res = vim
    .system({
      'curl',
      '-s',
      '--user',
      c.user .. ':' .. c.secret,
      '-X',
      'POST',
      '-H',
      'Jenkins-Crumb:' .. crumb,
      '-F',
      'jenkinsfile=<' .. vim.fn.expand '%:p',
      c.url .. '/pipeline-model-converter/validate',
    }, { text = true })
    :wait()

  if res.code ~= 0 then
    vim.notify('curl failed: ' .. (res.stderr or ''), vim.log.levels.ERROR)
    return
  end

  local output = vim.trim(res.stdout)
  if output == 'Jenkinsfile successfully validated.' then
    vim.diagnostic.reset(namespace_id, 0)
    vim.notify('Jenkinsfile validated', vim.log.levels.INFO)
    return
  end

  local err_info = parse_error(output)
  if err_info then
    vim.diagnostic.set(namespace_id, 0, {
      {
        lnum = err_info.line,
        col = err_info.col,
        severity = vim.diagnostic.severity.ERROR,
        message = err_info.msg,
        source = 'jenkins',
      },
    })
  else
    vim.notify('Validation failed: ' .. output, vim.log.levels.ERROR)
  end
end

return {
  validate = validate,
  clear_creds = function()
    creds = nil
  end,
}
