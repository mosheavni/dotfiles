local model = 'claude-sonnet-4.5'
return {
  {
    'zbirenbaum/copilot.lua',
    event = { 'InsertEnter' },
    config = function()
      require('copilot').setup {
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
      { '<leader>ccc', '<cmd>CopilotChat<CR>', mode = { 'n', 'v' } },
      { '<leader>ccs', '<cmd>CopilotChatStop<CR>' },
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
    'yetone/avante.nvim',
    build = 'make',
    enabled = true,
    version = false, -- Never set this value to "*"! Never!
    keys = {
      { '<leader>ccc', '<cmd>AvanteChat<CR>', mode = { 'n', 'v' } },
      { '<leader>ccs', '<cmd>AvanteStop<CR>' },
    },
    cmd = { 'AvanteChat' },
    ---@module 'avante'
    ---@type avante.Config
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
      {
        -- support for image pasting
        'HakonHarnes/img-clip.nvim',
        event = 'VeryLazy',
        keys = { { '<leader>p', '<cmd>PasteImage<cr>', desc = 'Paste image from system clipboard', ft = { 'AvanteInput' } } },
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { 'markdown', 'Avante' },
        },
        ft = { 'markdown', 'Avante' },
      },
    },
  },
}
