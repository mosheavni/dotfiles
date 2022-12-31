local utils = require 'user.utils'
local nmap = utils.nmap
local nnoremap = utils.nnoremap
local tnoremap = utils.tnoremap

local M =
  {
    -------------------
    --   Colorscheme --
    -------------------
    {
      'navarasu/onedark.nvim',
      config = function()
        require('onedark').setup {
          style = 'dark',
        }
        require('onedark').load()
      end,
    },
    {
      'dstein64/vim-startuptime',
      cmd = 'StartupTime',
    },

    ---------
    -- Git --
    ---------
    {
      'mosheavni/vim-to-github',
      cmd = { 'ToGithub' },
    },
    {
      'sindrets/diffview.nvim',
      dependencies = 'nvim-lua/plenary.nvim',
      cmd = {
        'DiffviewClose',
        'DiffviewFileHistory',
        'DiffviewFocusFiles',
        'DiffviewLog',
        'DiffviewOpen',
        'DiffviewRefresh',
        'DiffviewToggleFiles',
      },
      config = function()
        require 'diffview'
      end,
    },

    ------------------------------------
    -- Language Server Protocol (LSP) --
    ------------------------------------
    {
      'folke/trouble.nvim',
      config = true,
      cmd = 'TroubleToggle',
    },
    {
      'vim-scripts/groovyindent-unix',
      ft = { 'groovy', 'Jenkinsfile' },
    },
    {
      'sam4llis/nvim-lua-gf',
      ft = 'lua',
    },
    {
      'martinda/Jenkinsfile-vim-syntax',
      ft = { 'groovy', 'Jenkinsfile' },
    },
    {
      'chr4/nginx.vim',
      ft = 'nginx',
    },
    {
      'mosheavni/vim-kubernetes',
      event = 'VeryLazy',
    },
    {
      'towolf/vim-helm',
      ft = { 'yaml', 'yaml.gotexttmpl' },
    },
    {
      'phelipetls/jsonpath.nvim',
      ft = 'json',
      config = function()
        vim.api.nvim_buf_create_user_command(0, 'JsonPath', function()
          local json_path = require('jsonpath').get()
          local register = '+'
          vim.fn.setreg(register, json_path)
          vim.notify('Copied ' .. json_path .. ' to register ' .. register, vim.log.levels.INFO, { title = 'JsonPath' })
        end, {})
      end,
    },
    {
      'chrisbra/vim-sh-indent',
      ft = { 'sh', 'bash', 'zsh' },
    },
    {
      'milisims/nvim-luaref',
      event = 'VeryLazy',
    },
    {
      'nanotee/luv-vimdocs',
      event = 'VeryLazy',
    },

    ----------------
    -- Completion --
    ----------------
    {
      'phenomenes/ansible-snippets',
      ft = { 'ansible', 'yaml.ansible' },
      config = function()
        vim.g['ansible_goto_role_paths'] = '.;,roles;'
      end,
    },

    -----------------------------
    -- AI and smart completion --
    -----------------------------
    -- {
    --   'github/copilot.vim',
    --   event = 'InsertEnter',
    --   config = function()
    --     vim.cmd [[
    --       imap <silent><script><expr> <M-Enter> copilot#Accept("\<CR>")
    --       " imap <silent> <c-]> <Plug>(copilot-next)
    --       " inoremap <silent> <c-[> <Plug>(copilot-previous)
    --       let g:copilot_no_tab_map = v:true
    --     ]]
    --   end,
    -- },
    {
      'zbirenbaum/copilot.lua',
      event = 'InsertEnter',
      config = function()
        vim.schedule(function()
          require('copilot').setup {
            panel = {
              enabled = true,
              auto_refresh = false,
              keymap = {
                jump_prev = '[[',
                jump_next = ']]',
                accept = '<CR>',
                refresh = 'gr',
                open = '<M-l>',
              },
            },
            suggestion = {
              auto_trigger = true,
              keymap = {
                accept = '<M-Enter>',
              },
            },
          }
        end)
      end,
    },
    {
      'aduros/ai.vim',
      cmd = 'AI',
      config = function()
        vim.g.ai_no_mappings = true
        nnoremap('<M-a>', ':AI ')
        vnoremap('<M-a>', ':AI ')
        inoremap('<M-a>', '<Esc>:AI<CR>a')
      end,
    },
    {
      'jackMort/ChatGPT.nvim',
      config = true,
      dependencies = {
        'MunifTanjim/nui.nvim',
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
      },
      cmd = 'ChatGPT',
    },

    -------------------------
    -- Functionality Tools --
    -------------------------
    {
      'monkoose/matchparen.nvim',
      keys = { '%' },
      config = true,
    },
    {
      'kiran94/s3edit.nvim',
      cmd = 'S3Edit',
      config = true,
    },
    {
      'voldikss/vim-floaterm',
      keys = { 'F6', 'F7', 'F8' },
      cmd = {
        'FloatermFirst',
        'FloatermHide',
        'FloatermKill',
        'FloatermLast',
        'FloatermNew',
        'FloatermNext',
        'FloatermPrev',
        'FloatermSend',
        'FloatermShow',
        'FloatermToggle',
        'FloatermUpdate',
      },
      config = function()
        nnoremap('<F6>', '<Cmd>FloatermToggle<CR>', true)
        nnoremap('<F7>', '<Cmd>FloatermNew<CR>', true)
        nnoremap('<F8>', '<Cmd>FloatermNext<CR>', true)
        vim.g['floaterm_height'] = 0.9
        vim.g['floaterm_keymap_new'] = '<F7>'
        vim.g['floaterm_keymap_next'] = '<F8>'
        vim.g['floaterm_keymap_toggle'] = '<F6>'
        vim.g['floaterm_width'] = 0.7
      end,
    },
    {
      'samjwill/nvim-unception',
      event = 'VeryLazy',
    },
    {
      'mosheavni/vim-dirdiff',
      cmd = { 'DirDiff' },
    },
    {
      'simeji/winresizer',
      keys = { '<C-e>' },
      config = function()
        vim.g.winresizer_vert_resize = 4
        vim.g.winresizer_start_key = '<C-E>'
        tnoremap('<C-E>', '<Esc><Cmd>WinResizerStartResize<CR>', true)
      end,
    },
    {
      'pechorin/any-jump.vim',
      cmd = { 'AnyJump', 'AnyJumpVisual' },
      keys = { '<leader>j' },
      config = function()
        nnoremap('<leader>j', '<cmd>AnyJump<CR>')
      end,
    },
    {
      'kazhala/close-buffers.nvim',
      config = true,
      cmd = { 'BDelete', 'BWipeout' },
    },
    {
      'iamcco/markdown-preview.nvim',
      build = 'cd app && yarn install',
      config = function()
        vim.g.mkdp_filetypes = { 'markdown' }
      end,
      cmd = 'MarkdownPreview',
      ft = 'markdown',
    },
    {
      'jdhao/better-escape.vim',
      event = 'InsertEnter',
    },

    --------------
    -- Quickfix --
    --------------
    {
      url = 'https://gitlab.com/yorickpeterse/nvim-pqf.git',
      config = true,
      event = 'BufWinEnter',
      -- ft = 'qf',
    },
    {
      'tommcdo/vim-lister',
      ft = 'qf',
      cmd = { 'Qfilter', 'Qgrep' },
    }, -- Qfilter and Qgrep on Quickfix
    {
      'kevinhwang91/nvim-bqf',
      ft = 'qf',
    },

    -----------------
    -- Look & Feel --
    -----------------
    {
      'stevearc/dressing.nvim',
      config = function()
        require('dressing').setup {
          select = {
            telescope = require('telescope.themes').get_dropdown {
              layout_config = {
                width = 0.4,
                height = 0.8,
              },
            },
          },
          input = {
            enabled = false,
          },
        }
        vim.cmd [[hi link FloatTitle Normal]]
      end,
      event = 'VeryLazy',
    },
    {
      'RRethy/vim-illuminate',
      event = 'VeryLazy',
    },

    {
      'kyazdani42/nvim-web-devicons',
      event = 'VeryLazy',
    },
    {
      'goolord/alpha-nvim',
      config = function()
        local startify = require 'alpha.themes.startify'
        require('alpha').setup(startify.config)
      end,
    },
    {
      'vim-scripts/CursorLineCurrentWindow',
      event = 'VeryLazy',
    },
    {
      'norcalli/nvim-colorizer.lua',
      config = true,
      event = 'BufReadPre',
    },

    ------------
    -- Themes --
    ------------
    -- 'Mofiqul/vscode.nvim',
    -- 'cpea2506/one_monokai.nvim',
    -- 'drewtempelmeyer/palenight.vim',
    -- 'ellisonleao/gruvbox.nvim',
    -- 'folke/tokyonight.nvim',
    -- 'ghifarit53/tokyonight-vim',
    -- 'jacoborus/tender.vim',
    -- 'joshdick/onedark.vim',
    -- 'marko-cerovac/material.nvim',
    -- 'rafamadriz/neon',
    -- 'rebelot/kanagawa.nvim',
    -- { 'dracula/vim', as = 'dracula' },
    -- { 'luisiacc/gruvbox-baby', branch = 'main' },
    -- {
    --   'catppuccin/nvim',
    --   name = 'catppuccin',
    -- },

    -----------------------
    -- Text Manipulation --
    -----------------------
    {
      'tpope/vim-repeat',
      event = 'VeryLazy',
    },
    {
      'tpope/vim-surround',
      keys = { 'ds', 'cs', 'ys', { 'S', nil, mode = 'v' } },
    },
    {
      'numToStr/Comment.nvim',
      config = function()
        require('Comment').setup {
          pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
        }
      end,
      keys = { 'gc', 'gcc', { 'gc', nil, mode = 'v' } },
      dependencies = {
        'JoosepAlviste/nvim-ts-context-commentstring',
      },
    },
    {
      'junegunn/vim-easy-align',
      event = 'VeryLazy',
      config = function()
        nmap('ga', '<Plug>(EasyAlign)')
      end,
    },
    {
      'nguyenvukhang/nvim-toggler',
      keys = { 'gs' },
      config = function()
        require('nvim-toggler').setup {
          remove_default_keybinds = true,
          inverses = {
            ['enable'] = 'disable',
          },
        }
        vim.keymap.set({ 'n', 'v' }, 'gs', require('nvim-toggler').toggle)
      end,
    },
    {
      'ggandor/leap.nvim',
      event = 'VeryLazy',
      config = function()
        nnoremap('s', '<Plug>(leap-forward-to)', true)
        nnoremap('S', '<Plug>(leap-backward-to)', true)
      end,
    },
    {
      'windwp/nvim-ts-autotag',
      ft = { 'html', 'javascript' },
    },
    {
      'gpanders/editorconfig.nvim',
      event = 'VeryLazy',
    },
    {
      'axelvc/template-string.nvim',
      ft = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'python' },
      event = 'InsertEnter',
      config = true,
    },
    {
      'mizlan/iswap.nvim',
      cmd = { 'ISwap', 'ISwapWith' },
      config = function()
        require('iswap').setup()
        nmap('<leader>sw', ':ISwapWith<CR>')
      end,
    },
    {
      'vim-scripts/ReplaceWithRegister',
      event = 'VeryLazy',
    },

    -- DONE ✅
  },
  {
    change_detection = {
      notify = true,
    },
    ui = {
      border = 'rounded',
      custom_keys = {
        ['<localleader>l'] = function(plugin)
          require('lazy.util').open_cmd({ 'git', 'log' }, {
            cwd = plugin.dir,
            terminal = true,
            close_on_exit = true,
            enter = true,
          })
        end,

        -- open a terminal for the plugin dir
        ['<localleader>t'] = function(plugin)
          vim.cmd('FloatermNew --cwd=' .. plugin.dir)
        end,
      },
    },
    diff = {
      cmd = 'diffview.nvim',
    },
    checker = {
      -- automatically check for plugin updates
      enabled = true,
    },
    performance = {
      rtp = {
        disabled_plugins = {
          'rplugin',
          'gzip',
          'matchit',
          'matchparen',
          'shada',
          'tarPlugin',
          'tohtml',
          'tutor',
          'zipPlugin',
        },
      },
    },
  }

return M
