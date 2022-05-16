local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

local actions = require("telescope.actions")


telescope.setup {
  -- defaults = { sorting_strategy = "ascending" },
  defaults = {
    mappings = {
      i = {
        ["<esc>"] = actions.close
      },
    },
  },
  pickers = {
    find_files = {
      find_command = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--files",
        "--trim",
        "--column",
        "--hidden",
        "--smart-case",
        "-g",
        "!.git/",
      }
    },
  }
}

require('telescope').load_extension('fzf')
