require('spectre').setup({

  find_engine = {
    -- rg is map with finder_cmd
    ['rg'] = {
      cmd = "rg",
      -- default args
      args = {
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
      },
      options = {
        ['ignore-case'] = {
          value = "--ignore-case",
          icon = "[I]",
          desc = "ignore case"
        },
        ['hidden'] = {
          value = "--hidden",
          desc = "hidden file",
          icon = "[H]"
        },
        ['literal'] = {
          value = "-F",
          desc = "literal search",
          icon = "[F]"
        },
        -- you can put any rg search option you want here it can toggle with
        -- show_option function
      }
    },
    ['ag'] = {
      cmd = "ag",
      args = {
        '--vimgrep',
        '-s'
      },
      options = {
        ['ignore-case'] = {
          value = "-i",
          icon = "[I]",
          desc = "ignore case"
        },
        ['hidden'] = {
          value = "--hidden",
          desc = "hidden file",
          icon = "[H]"
        },
        ['literal'] = {
          value = "-Q",
          desc = "literal search",
          icon = "[F]"
        },
      },
    },
  },
  default = {
    find = {
      cmd = "rg",
      options = { "ignore-case", "hidden" }
    },
  },
})
