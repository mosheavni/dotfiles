local user = os.getenv 'JENKINS_USER_ID' or os.getenv 'JENKINS_USERNAME'
local password = os.getenv 'JENKINS_PASSWORD'
local token = os.getenv 'JENKINS_API_TOKEN' or os.getenv 'JENKINS_TOKEN'
local jenkins_url = os.getenv 'JENKINS_URL' or os.getenv 'JENKINS_HOST'
local op_jenkins_id = os.getenv 'OP_JENKINS_ID' or 't5ejcfcrjyo243irr2bjy3yqhm'
local namespace_id = vim.api.nvim_create_namespace 'jenkinsfile-linter'
local validated_msg = 'Jenkinsfile successfully validated.'
-- local unauthorized_msg = 'ERROR 401 Unauthorized'
-- local not_found_msg = 'ERROR 404 Not Found'

local M = {}

local function check_creds()
  if user == nil then
    return false, 'JENKINS_USER_ID is not set, please set it'
  elseif password == nil and token == nil then
    return false, 'JENKINS_PASSWORD or JENKINS_API_TOKEN need to be set, please set one'
  elseif jenkins_url == nil then
    return false, 'JENKINS_URL is not set, please set it'
  else
    return true
  end
end

local function get_crumb_job()
  local args = {
    'curl',
    '-s',
    '--user',
    user .. ':' .. (token or password),
    jenkins_url .. '/crumbIssuer/api/json',
  }
  local data = vim.system(args, { text = true }):wait()
  local ok, crumb = pcall(vim.json.decode, data.stdout)
  if not ok then
    vim.notify('error decoding json ' .. vim.inspect(crumb))
    return
  end
  return crumb.crumb
end

local validate_job = vim.schedule_wrap(function(crumb_job)
  local args = {
    'curl',
    '-s',
    '--user',
    user .. ':' .. (token or password),
    '-X',
    'POST',
    '-H',
    'Jenkins-Crumb:' .. crumb_job,
    '-F',
    'jenkinsfile=<' .. vim.fn.expand '%:p',
    jenkins_url .. '/pipeline-model-converter/validate',
  }
  local res = vim.system(args, { text = true }):wait()
  if res.code == 0 then
    local data = vim.trim(res.stdout)
    if data == validated_msg then
      vim.diagnostic.reset(namespace_id, 0)
      vim.notify(validated_msg, vim.log.levels.INFO)
    else
      -- We only want to grab the msg, line, and col. We just throw
      -- everything else away. NOTE: That only one seems to ever be
      -- returned so this in theory will only ever match at most once per
      -- call.
      --WorkflowScript: 46: unexpected token: } @ line 46, column 1.
      local msg, line_str, col_str = data:match 'WorkflowScript.+%d+: (.+) @ line (%d+), column (%d+).'
      if line_str and col_str then
        local line = tonumber(line_str) - 1
        local col = tonumber(col_str) - 1

        local diag = {
          bufnr = vim.api.nvim_get_current_buf(),
          lnum = line,
          end_lnum = line,
          col = col,
          end_col = col,
          severity = vim.diagnostic.severity.ERROR,
          message = msg,
          source = 'jenkins validate',
        }

        vim.diagnostic.set(namespace_id, vim.api.nvim_get_current_buf(), { diag })
      end
    end
  end
end)

local onepass_creds = function()
  local is_op_exists = vim.fn.executable 'op' == 1
  if not is_op_exists then
    vim.notify('1Password CLI is not installed', vim.log.levels.ERROR)
    vim.notify('Install with brew install 1password-cli', vim.log.levels.INFO)
    return false
  end
  local onepass = vim
    .system({
      'op',
      'item',
      'get',
      op_jenkins_id,
      '--reveal',
      '--format',
      'json',
    })
    :wait()
  if onepass.code ~= 0 then
    return false
  end
  local creds = vim.json.decode(vim.trim(onepass.stdout))

  for _, field in ipairs(creds.fields) do
    if field.purpose == 'USERNAME' then
      user = field.value
    elseif field.purpose == 'PASSWORD' then
      password = field.value
    end
  end
  jenkins_url = creds.urls[1].href
  return true
end

local function ok_and_validate(should_notify)
  local ok, msg = check_creds()
  if ok then
    validate_job(get_crumb_job())
    return true
  elseif should_notify then
    vim.notify(msg, vim.log.levels.ERROR)
  end
  return false
end

M.validate = function()
  if not ok_and_validate(false) then
    local is_onepass = onepass_creds()
    if is_onepass then
      ok_and_validate(true)
    else
      vim.notify('Credentials not set', vim.log.levels.ERROR)
    end
  end
end

return M
