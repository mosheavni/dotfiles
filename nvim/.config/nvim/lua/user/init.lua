vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.python3_host_prog = vim.fn.expand '~/.local/share/dotfiles-python/bin/python3'

-- Disable bundled runtime plugins we never use (reduces startup work).
vim.g.loaded_2html_plugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_remote_plugins = 1
vim.g.loaded_shada_autoload = 1
vim.g.loaded_shada_plugin = 1
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1

-------------
-- modules --
-------------
require('user.colorscheme').setup()
require 'user.commands'

--------------
-- Put Text --
--------------
function _G.put_text(...)
  local objects = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local lines = vim.split(table.concat(objects, '\n'), '\n')
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end

------------------------
-- Write to temp file --
------------------------
---Write a temporary file with specified options
---@param opts? {should_delete?: boolean, ft?: string, new?: boolean, vertical?: boolean, reload?: boolean}
---@return string tmp The path to the temporary file
function _G.tmp_write(opts)
  opts = opts or {}
  local final_opts = vim.tbl_deep_extend('force', {
    should_delete = true,
    ft = nil,
    new = true,
    vertical = false,
    reload = true,
  }, opts)

  local tmp = vim.fn.tempname()

  if final_opts.new then
    vim.cmd(final_opts.vertical and 'vnew' or 'new')
  end

  if final_opts.ft then
    local extension = require('user.utils').filetype_to_extension[final_opts.ft] or final_opts.ft
    vim.bo.filetype = final_opts.ft
    tmp = tmp .. '.' .. extension
  end

  vim.cmd('write ' .. vim.fn.fnameescape(tmp))
  if final_opts.reload then
    vim.cmd 'edit'
  end

  if final_opts.should_delete then
    -- global on purpose: a buffer-local autocmd for VimLeavePre only fires
    -- when that buffer is current at exit, leaking the temp file otherwise
    vim.api.nvim_create_autocmd('VimLeavePre', {
      callback = function()
        vim.fn.delete(tmp)
      end,
    })
  end
  return tmp
end

---------------
-- Filetypes --
---------------
local kube_config_pattern = [[.*\.kube/config]]

---@param bufnr integer
---@return boolean
local function mark_k8s_yaml(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 20, false)) do
    if line:match '^kind:' or line:match '^apiVersion:' then
      vim.b[bufnr].is_kubernetes = true
      return true
    end
  end
  return false
end

local function yaml_extension(_, bufnr)
  mark_k8s_yaml(bufnr)
  return 'yaml'
end

vim.filetype.add {
  extension = { tfvars = 'terraform', yaml = yaml_extension, yml = yaml_extension },
  filename = {
    Brewfile = 'brewfile',
    ['corp-Brewfile'] = 'brewfile',
    ['Chart.yaml'] = 'yaml.chart',
    ['package.json'] = 'json.package',
    ['.pre-commit-config.yaml'] = 'yaml.precommit',
    ['.pre-commit-config.yml'] = 'yaml.precommit',
    ['docker-compose.yml'] = 'yaml.docker-compose',
  },
  pattern = {
    ['.*/templates/.*%.yaml'] = {
      function(_, bufnr)
        for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
          if line:find '{{.+}}' then
            return 'helm'
          end
        end
      end,
      { priority = 200 },
    },
    ['.*/.github/workflows/.*%.yml'] = 'yaml.ghaction',
    ['.*Jenkinsfile.*'] = 'groovy',
    [kube_config_pattern] = 'yaml',
    ['.*'] = {
      function(_, bufnr)
        if mark_k8s_yaml(bufnr) then
          return 'yaml'
        end
      end,
      -- catch-all must lose to every specific pattern (:h vim.filetype.add)
      { priority = -math.huge },
    },
  },
}
