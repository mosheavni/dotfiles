vim.cmd [[
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
]]

require('user.options')
vim.cmd [[
source ~/.vimrcplugins
]]
