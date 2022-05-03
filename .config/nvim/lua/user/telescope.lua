local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

telescope.setup {
  pickers = {
    find_files = {
      find_command = { "rg", "--files", "--hidden", "-g", "!.git/", "--color=never" }
    },
  }
}
require('telescope').load_extension('fzf')
