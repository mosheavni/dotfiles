---@diagnostic disable: undefined-field, need-check-nil
--# selene: allow(undefined_variable)
local utils = require 'user.utils'
local eq = assert.are.same

describe('user.utils', function()
  describe('country_os_to_emoji', function()
    it('converts US to flag emoji', function()
      eq(utils.country_os_to_emoji 'US', '🇺🇸')
    end)

    it('converts GB to flag emoji', function()
      eq(utils.country_os_to_emoji 'GB', '🇬🇧')
    end)

    it('converts IL to flag emoji', function()
      eq(utils.country_os_to_emoji 'IL', '🇮🇱')
    end)

    it('converts DE to flag emoji', function()
      eq(utils.country_os_to_emoji 'DE', '🇩🇪')
    end)

    it('converts JP to flag emoji', function()
      eq(utils.country_os_to_emoji 'JP', '🇯🇵')
    end)
  end)

  describe('random_emoji', function()
    it('returns a string', function()
      local emoji = utils.random_emoji()
      assert.is_string(emoji)
    end)

    it('returns a non-empty string', function()
      local emoji = utils.random_emoji()
      assert.is_true(#emoji > 0)
    end)

    it('returns different values on multiple calls (probabilistic)', function()
      local emojis = {}
      for _ = 1, 20 do
        table.insert(emojis, utils.random_emoji())
      end
      -- Check that we got at least 2 different emojis in 20 tries
      local unique = {}
      for _, emoji in ipairs(emojis) do
        unique[emoji] = true
      end
      local count = 0
      for _ in pairs(unique) do
        count = count + 1
      end
      assert.is_true(count > 1)
    end)
  end)

  describe('read_json_file', function()
    local test_file = '/tmp/nvim_test_json.json'

    after_each(function()
      os.remove(test_file)
    end)

    it('reads valid JSON file', function()
      local file = io.open(test_file, 'w')
      file:write '{"key": "value", "number": 42}'
      file:close()

      local result = utils.read_json_file(test_file)
      assert.is_not_nil(result)
      eq(result.key, 'value')
      eq(result.number, 42)
    end)

    it('returns nil for non-existent file', function()
      local result = utils.read_json_file '/tmp/non_existent_file_12345.json'
      assert.is_nil(result)
    end)

    it('returns nil for invalid JSON', function()
      local file = io.open(test_file, 'w')
      file:write 'invalid json {'
      file:close()

      local result = utils.read_json_file(test_file)
      assert.is_nil(result)
    end)

    it('handles empty JSON object', function()
      local file = io.open(test_file, 'w')
      file:write '{}'
      file:close()

      local result = utils.read_json_file(test_file)
      assert.is_not_nil(result)
      assert.is_table(result)
    end)

    it('handles JSON arrays', function()
      local file = io.open(test_file, 'w')
      file:write '[1, 2, 3]'
      file:close()

      local result = utils.read_json_file(test_file)
      assert.is_not_nil(result)
      eq(result[1], 1)
      eq(result[2], 2)
      eq(result[3], 3)
    end)

    it('handles nested JSON structures', function()
      local file = io.open(test_file, 'w')
      file:write '{"outer": {"inner": "value"}}'
      file:close()

      local result = utils.read_json_file(test_file)
      assert.is_not_nil(result)
      eq(result.outer.inner, 'value')
    end)
  end)

  describe('filetype_to_extension', function()
    it('maps common filetypes to extensions', function()
      eq(utils.filetype_to_extension.python, 'py')
      eq(utils.filetype_to_extension.javascript, 'js')
      eq(utils.filetype_to_extension.typescript, 'ts')
      eq(utils.filetype_to_extension.rust, 'rs')
      eq(utils.filetype_to_extension.markdown, 'md')
    end)
  end)

  describe('filetype_to_command', function()
    it('maps filetypes to execution commands', function()
      eq(utils.filetype_to_command.python, 'python3')
      eq(utils.filetype_to_command.javascript, 'node')
      eq(utils.filetype_to_command.go, 'go')
      eq(utils.filetype_to_command.json, 'jq')
    end)
  end)

  describe('for_each_client', function()
    local orig_get_clients

    before_each(function()
      orig_get_clients = vim.lsp.get_clients
    end)

    after_each(function()
      vim.lsp.get_clients = orig_get_clients
    end)

    ---@param supports_result boolean
    ---@param calls table Filled with `argc`/`method` from the last `supports_method` call.
    local function make_spy_client(supports_result, calls)
      return {
        name = 'spy',
        supports_method = function(_, method, ...)
          calls.method = method
          calls.argc = select('#', ...)
          return supports_result
        end,
      }
    end

    it('with nil bufnr: calls get_clients() unfiltered and supports_method with no bufnr arg', function()
      local filter_arg = 'unset'
      local calls = {}
      local client = make_spy_client(true, calls)
      vim.lsp.get_clients = function(filter)
        filter_arg = filter
        return { client }
      end

      local received = {}
      utils.for_each_client(nil, 'textDocument/formatting', function(c)
        table.insert(received, c)
      end)

      eq(filter_arg, nil)
      eq(calls.argc, 0)
      eq(#received, 1)
    end)

    it('with a bufnr: filters get_clients by bufnr and passes bufnr to supports_method', function()
      local filter_arg
      local calls = {}
      local client = make_spy_client(true, calls)
      vim.lsp.get_clients = function(filter)
        filter_arg = filter
        return { client }
      end

      local received = {}
      utils.for_each_client(7, 'textDocument/formatting', function(c)
        table.insert(received, c)
      end)

      eq(filter_arg, { bufnr = 7 })
      eq(calls.argc, 1)
      eq(#received, 1)
    end)

    it('excludes a client whose supports_method returns false, even with a bufnr set', function()
      local calls = {}
      local client = make_spy_client(false, calls)
      vim.lsp.get_clients = function()
        return { client }
      end

      local received = {}
      utils.for_each_client(7, 'textDocument/formatting', function(c)
        table.insert(received, c)
      end)

      eq(#received, 0)
    end)
  end)

  describe('command_for_filetype', function()
    it('returns the mapped command for a known filetype', function()
      eq(utils.command_for_filetype 'yaml', 'yq')
      eq(utils.command_for_filetype 'python', 'python3')
    end)

    it('falls back to the base filetype before the dot', function()
      eq(utils.command_for_filetype 'yaml.docker-compose', 'yq')
    end)

    it('uses act for GitHub Actions workflow files', function()
      eq(utils.command_for_filetype 'yaml.ghaction', 'act')
    end)

    it('defaults to bash for unknown filetypes', function()
      eq(utils.command_for_filetype 'unknown', 'bash')
    end)
  end)
end)
