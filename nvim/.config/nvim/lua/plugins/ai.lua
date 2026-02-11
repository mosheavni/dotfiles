local model = 'claude-sonnet-4.5'
local ai_keymap = '<leader>ccc'
return {
  {
    'zbirenbaum/copilot.lua',
    event = { 'InsertEnter' },
    -- dependencies = {
    --   'copilotlsp-nvim/copilot-lsp',
    --   init = function()
    --     vim.g.copilot_nes_debounce = 500
    --   end,
    -- }, -- re-enable when NES is more stable
    config = function()
      require('copilot').setup {
        -- nes = {
        --   enabled = false,
        --   auto_trigger = true,
        --   keymap = {
        --     accept_and_goto = '<C-]>',
        --     accept = false,
        --     dismiss = '<Esc>',
        --   },
        -- },
        copilot_node_command = 'node',
        filetypes = { ['*'] = true },
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
    end,
  },
  {
    'ravitemer/mcphub.nvim',
    cmd = { 'MCPHub' },
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    build = 'npm install -g mcp-hub@latest', -- Installs `mcp-hub` node binary globally
    opts = {
      extensions = {
        avante = {
          enabled = true,
          make_slash_commands = true, -- make /slash commands from MCP server prompts
        },
        copilotchat = {
          enabled = false,
          convert_tools_to_functions = true, -- Convert MCP tools to CopilotChat functions
          convert_resources_to_functions = true, -- Convert MCP resources to CopilotChat functions
          add_mcp_prefix = true, -- Add "mcp_" prefix to function names
        },
      },
    },
  },
  {
    'carlos-algms/agentic.nvim',
    dependencies = { 'HakonHarnes/img-clip.nvim' },
    opts = {
      -- Available by default: "claude-acp" | "gemini-acp" | "codex-acp" | "opencode-acp" | "cursor-acp"
      provider = 'claude-acp', -- setting the name here is all you need to get started
      keymaps = { prompt = { paste_image = { { '<localleader>p', mode = { 'n' } } } } },
    },

    -- these are just suggested keymaps; customize as desired
    keys = {
      {
        ai_keymap,
        function() require('agentic').toggle() end,
        mode = { 'n', 'v', 'i' },
        desc = 'Toggle Agentic Chat',
      },
      {
        "<C-'>",
        function() require('agentic').add_selection_or_file_to_context() end,
        mode = { 'n', 'v' },
        desc = 'Add file or selection to Agentic to Context',
      },
      {
        '<C-,>',
        function() require('agentic').new_session() end,
        mode = { 'n', 'v', 'i' },
        desc = 'New Agentic Session',
      },
    },
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    enabled = false,
    cmd = {
      'CopilotChat',
      'CopilotChatAgents',
      'CopilotChatClose',
      'CopilotChatCommit',
      'CopilotChatCommitStaged',
      'CopilotChatDebugInfo',
      'CopilotChatDocs',
      'CopilotChatExplain',
      'CopilotChatFix',
      'CopilotChatFixDiagnostic',
      'CopilotChatLoad',
      'CopilotChatModels',
      'CopilotChatOpen',
      'CopilotChatOptimize',
      'CopilotChatReset',
      'CopilotChatReview',
      'CopilotChatSave',
      'CopilotChatStop',
      'CopilotChatTests',
      'CopilotChatToggle',
    },
    dependencies = {
      'zbirenbaum/copilot.lua',
      'nvim-lua/plenary.nvim',
      'ravitemer/mcphub.nvim',
    },
    build = 'make tiktoken',
    opts = {
      -- https://docs.github.com/en/copilot/using-github-copilot/ai-models/choosing-the-right-ai-model-for-your-task
      model = model,
      question_header = '  User ',
      answer_header = '  Copilot ',
      error_header = '  Error ',
    },
    keys = {
      { ai_keymap, '<cmd>CopilotChat<CR>', mode = { 'n', 'v' }, desc = 'Copilot Chat' },
      { '<leader>ccs', '<cmd>CopilotChatStop<CR>', desc = 'Stop Copilot Chat' },
      {
        '<leader>ccp',
        function()
          local actions = require 'CopilotChat.actions'
          require('CopilotChat.integrations.fzflua').pick(actions.prompt_actions())
        end,
        desc = 'CopilotChat - Prompt actions',
        mode = { 'n', 'v' },
      },
    },
  },
  {
    'coder/claudecode.nvim',
    enabled = false,
    opts = {},
    keys = {
      { ai_keymap, '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude' },
      -- { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude' },
      -- { '<leader>ar', '<cmd>ClaudeCode --resume<cr>', desc = 'Resume Claude' },
      -- { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'Continue Claude' },
      -- { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Select Claude model' },
      -- { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Add current buffer' },
      -- { '<leader>as', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Send to Claude' },
      {
        '<leader>cca',
        '<cmd>ClaudeCodeTreeAdd<cr>',
        desc = 'Add file',
        ft = { 'NvimTree', 'neo-tree', 'oil', 'minifiles', 'netrw' },
      },
      -- Diff management
      -- { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept diff' },
      -- { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Deny diff' },
    },
  },
  {
    'yetone/avante.nvim',
    build = 'make',
    enabled = false,
    version = false, -- Never set this value to "*"! Never!
    keys = {
      { ai_keymap, '<cmd>AvanteChat<CR>', mode = { 'n', 'v' }, desc = 'Avante Chat' },
      { '<leader>ccs', '<cmd>AvanteStop<CR>', desc = 'Stop Avante Chat' },
    },
    cmd = { 'AvanteChat' },
    opts = {
      disabled_tools = {
        'list_files', -- Built-in file operations
        'search_files',
        'read_file',
        'create_file',
        'rename_file',
        'delete_file',
        'create_dir',
        'rename_dir',
        'delete_dir',
        'bash', -- Built-in terminal access
      },
      provider = 'copilot',
      providers = {
        copilot = {
          model = model,
        },
      },

      -- mcphub
      -- system_prompt as function ensures LLM always has latest MCP server state
      -- This is evaluated for every message, even in existing chats
      system_prompt = function()
        local hub = require('mcphub').get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ''
      end,
      -- Using function prevents requiring mcphub before it's loaded
      custom_tools = function()
        return {
          require('mcphub.extensions.avante').mcp_tool(),
        }
      end,
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
    },
  },
  {
    -- support for image pasting
    'HakonHarnes/img-clip.nvim',
    lazy = true,
    -- opts = {
    --   -- recommended settings
    --   default = {
    --     embed_image_as_base64 = false,
    --     prompt_for_file_name = false,
    --     drag_and_drop = {
    --       insert_mode = true,
    --     },
    --     -- required for Windows users
    --     use_absolute_path = true,
    --   },
    -- },
  },
}
