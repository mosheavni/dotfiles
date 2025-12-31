local M = {}

M.url_prefix = 'https://github.com'

-- Remove surrounding quotes from a URL string
M.remove_quotes = function(url)
  return string.gsub(url, [[^["'](.*)["']$]], '%1')
end

-- Check if a string is an HTTP(S) URL
M.is_http_url = function(url)
  return string.match(url, [[^https?://.*]]) ~= nil
end

-- Check if a string matches user/repo pattern
M.is_user_repo = function(url)
  return string.match(url, [[.*/.*]]) ~= nil
end

-- Parse user/repo@branch format and return url and suffix
M.parse_user_repo = function(url)
  local suffix = ''
  local repo_url = url

  -- check if string has @
  if string.match(url, [[.*@.*]]) then
    suffix = '/tree/' .. string.gsub(url, [[.*@(.*)]], '%1')
    repo_url = string.gsub(url, [[(.*)@.*]], '%1')
  end

  return repo_url, suffix
end

-- Build GitHub URL from user/repo pattern
M.build_github_url = function(repo, suffix)
  suffix = suffix or ''
  return M.url_prefix .. '/' .. repo .. suffix
end

-- Extract all HTTP(S) links from lines
M.extract_links_from_lines = function(lines)
  local links = {}
  for i, line in ipairs(lines) do
    for link in string.gmatch(line, [[(https?://[%w%.%-_/]+)]]) do
      table.insert(links, { line = i, link = link })
    end
  end
  return links
end

-- Process a URL string and return the final URL to open
M.process_url = function(url_string)
  local url = M.remove_quotes(url_string)

  -- If string starts with https://
  if M.is_http_url(url) then
    return url
  end

  -- If string matches `user/repo`
  if M.is_user_repo(url) then
    local repo, suffix = M.parse_user_repo(url)
    return M.build_github_url(repo, suffix)
  end

  return nil
end

M.open_url_under_cursor = function()
  local cword = vim.fn.expand '<cfile>'

  ---@diagnostic disable-next-line: param-type-mismatch
  local url = string.gsub(cword, [[[%w%-%.]+/[%w%-%.]+]], '%1')

  local processed_url = M.process_url(url)
  if processed_url then
    return vim.ui.open(processed_url)
  end

  -- if not cword, find all http(s) links in the file and use vim.ui.select to choose one
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local links = M.extract_links_from_lines(lines)

  if #links == 0 then
    return vim.notify('No links found in the file', vim.log.levels.WARN)
  end

  vim.ui.select(links, {
    prompt = 'Select a link to open❯ ',
    format_item = function(item)
      return item.line .. ':🔗 ' .. item.link
    end,
  }, function(selected)
    if selected then
      vim.ui.open(selected.link)
    end
  end)
end

return M
