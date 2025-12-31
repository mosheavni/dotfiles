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
end)
