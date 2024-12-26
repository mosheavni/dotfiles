--# selene: allow(undefined_variable)
local utils = require 'user.utils'
local eq = assert.are.same

describe('user.utils', function()
  it('return an emoji of country', function()
    eq(utils.country_os_to_emoji 'US', '🇺🇸')
  end)
end)
