local autocmd = vim.api.nvim_create_autocmd
local augroup = function(name)
  vim.api.nvim_create_augroup(name, { clear = true })
end

local reload_file_group = augroup('ReloadFile')
autocmd({ 'FocusGained', 'BufEnter' }, {
  desc = 'Auto load file changes when focus or buffer is entered',
  group = reload_file_group,
  pattern = '*',
  command = 'if &buftype == "nofile" | checktime | endif'
})


local special_filetypes = augroup('SpecialFiletype')
autocmd({ "FileType" }, {
  group = special_filetypes,
  pattern = 'json',
  command = 'syntax match Comment +\\/\\/.\\+$+'
})
autocmd({ "BufNewFile", "BufRead" }, {
  group = special_filetypes,
  pattern = "aliases.sh",
  command = "setf zsh"
})
autocmd({ "BufNewFile", "BufRead" }, {
  group = special_filetypes,
  pattern = ".eslintrc",
  command = "setf json"
})
autocmd({ "BufNewFile", "BufRead" }, {
  group = special_filetypes,
  pattern = "*.hcl",
  command = "setf terraform"
})
autocmd({ "BufRead", "BufNewFile" }, {
  group = special_filetypes,
  pattern = { "*/templates/*.yaml", "*/templates/*.tpl", "*.gotmpl", "helmfile.yaml" },
  command = "set ft=helm"
})
autocmd({ "FileType" }, {
  group = special_filetypes,
  pattern = "javascript",
  command = "set filetype=javascriptreact | set iskeyword+=-"
})
autocmd({ "FileType" }, {
  group = special_filetypes,
  pattern = "nginx",
  command = "setlocal iskeyword+=$ | let b:coc_additional_keywords = ['$']"
})

autocmd({ 'BufWritePost' }, {
  group = special_filetypes,
  pattern = 'plugins.lua',
  command = 'source <afile> | PackerCompile',
})

local nvim_blame_line = augroup('NvimBlameLine')
autocmd({ 'BufEnter' }, {
  group = nvim_blame_line,
  pattern = '*',
  command = 'EnableBlameLine'
})
