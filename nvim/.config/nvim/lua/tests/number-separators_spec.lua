---@diagnostic disable: undefined-field
--# selene: allow(undefined_variable)
local number_separators = require 'user.number-separators'
local eq = assert.are.same

describe('user.number-separators', function()
  describe('format_number', function()
    it('formats thousands with comma', function()
      eq(number_separators.format_number '1000', '1,000')
    end)

    it('formats millions with commas', function()
      eq(number_separators.format_number '1000000', '1,000,000')
    end)

    it('formats billions with commas', function()
      eq(number_separators.format_number '1234567890', '1,234,567,890')
    end)

    it('does not format numbers less than 1000', function()
      eq(number_separators.format_number '999', '999')
      eq(number_separators.format_number '1', '1')
      eq(number_separators.format_number '42', '42')
    end)

    it('handles negative numbers', function()
      eq(number_separators.format_number '-1000', '-1,000')
      eq(number_separators.format_number '-1234567', '-1,234,567')
    end)

    it('handles decimal numbers', function()
      eq(number_separators.format_number '1000.5', '1,000.5')
      eq(number_separators.format_number '1234567.89', '1,234,567.89')
    end)

    it('handles negative decimal numbers', function()
      eq(number_separators.format_number '-1000.5', '-1,000.5')
      eq(number_separators.format_number '-9876543.21', '-9,876,543.21')
    end)

    it('preserves decimal places', function()
      eq(number_separators.format_number '1000.123456', '1,000.123456')
    end)

    it('handles numbers with only decimal part', function()
      eq(number_separators.format_number '0.5', '0.5')
      eq(number_separators.format_number '.5', '.5')
    end)

    it('handles edge case of exactly 3 digits', function()
      eq(number_separators.format_number '100', '100')
    end)

    it('handles edge case of exactly 4 digits', function()
      eq(number_separators.format_number '1234', '1,234')
    end)

    it('handles edge case of exactly 6 digits', function()
      eq(number_separators.format_number '123456', '123,456')
    end)

    it('handles edge case of exactly 7 digits', function()
      eq(number_separators.format_number '1234567', '1,234,567')
    end)
  end)
end)
