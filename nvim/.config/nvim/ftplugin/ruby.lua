local function sort_brewfile()
  if vim.fn.expand '%:t' ~= 'Brewfile' then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local taps = {}
  local brews = {}
  local casks = {}
  local others = {}

  for _, line in ipairs(lines) do
    if line:match '^tap ' then
      table.insert(taps, line)
    elseif line:match '^brew ' then
      table.insert(brews, line)
    elseif line:match '^cask ' then
      table.insert(casks, line)
    else
      table.insert(others, line)
    end
  end

  table.sort(taps)
  table.sort(brews)
  table.sort(casks)

  local sorted_lines = {}
  for _, line in ipairs(taps) do
    table.insert(sorted_lines, line)
  end
  for _, line in ipairs(brews) do
    table.insert(sorted_lines, line)
  end
  for _, line in ipairs(casks) do
    table.insert(sorted_lines, line)
  end
  for _, line in ipairs(others) do
    table.insert(sorted_lines, line)
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, sorted_lines)
end

if vim.fn.expand '%:t' == 'Brewfile' then
  -- autocmd BufWritePre

  vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('SortBrewfile', { clear = true }),
    pattern = 'Brewfile',
    callback = sort_brewfile,
  })
end
