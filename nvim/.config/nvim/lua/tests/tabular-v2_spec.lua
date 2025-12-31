---@diagnostic disable: undefined-field
--# selene: allow(undefined_variable)
local tabular = require 'user.tabular-v2'
local eq = assert.are.same

describe('user.tabular-v2', function()
  describe('raw_parse', function()
    it('parses tab-delimited data', function()
      local lines = {
        'Name\tAge\tCity',
        'Alice\t30\tNew York',
        'Bob\t25\tLondon',
        'Charlie\t35\tParis',
      }
      local result = tabular.raw_parse(lines, '\t')

      eq(result.headers, { 'Name', 'Age', 'City' })
      eq(#result.lines, 3)
      eq(result.lines[1], { 'Alice', '30', 'New York' })
      eq(result.lines[2], { 'Bob', '25', 'London' })
      eq(result.lines[3], { 'Charlie', '35', 'Paris' })
      eq(result.col_widths[1], 7) -- max of "Name" (4) and "Charlie" (7)
      eq(result.col_widths[2], 3) -- max of "Age" (3) and "30" (2), "25" (2), "35" (2)
      eq(result.col_widths[3], 8) -- max of "City" (4) and "New York" (8)
    end)

    it('parses space-delimited data', function()
      local lines = {
        'ID    Name      Status',
        '1     Active    Running',
        '2     Inactive  Stopped',
      }
      local result = tabular.raw_parse(lines, '  ')

      eq(result.headers, { 'ID', 'Name', 'Status' })
      eq(#result.lines, 2)
      eq(result.lines[1], { '1', 'Active', 'Running' })
      eq(result.lines[2], { '2', 'Inactive', 'Stopped' })
    end)

    it('handles custom delimiter', function()
      local lines = {
        'First|Second|Third',
        'A|B|C',
        'D|E|F',
      }
      local result = tabular.raw_parse(lines, '|')

      eq(result.headers, { 'First', 'Second', 'Third' })
      eq(#result.lines, 2)
      eq(result.lines[1], { 'A', 'B', 'C' })
      eq(result.lines[2], { 'D', 'E', 'F' })
    end)

    it('handles comma delimiter', function()
      local lines = {
        'Name,Age,Occupation',
        'John,28,Engineer',
        'Jane,32,Designer',
      }
      local result = tabular.raw_parse(lines, ',')

      eq(result.headers, { 'Name', 'Age', 'Occupation' })
      eq(#result.lines, 2)
      eq(result.lines[1], { 'John', '28', 'Engineer' })
      eq(result.lines[2], { 'Jane', '32', 'Designer' })
    end)

    it('removes empty lines', function()
      local lines = {
        'Col1\tCol2',
        '',
        'Val1\tVal2',
        '',
        'Val3\tVal4',
        '',
      }
      local result = tabular.raw_parse(lines, '\t')

      eq(result.headers, { 'Col1', 'Col2' })
      eq(#result.lines, 2)
      eq(result.lines[1], { 'Val1', 'Val2' })
      eq(result.lines[2], { 'Val3', 'Val4' })
    end)

    it('trims whitespace from values', function()
      local lines = {
        '  Name  \t  Age  ',
        '  Alice  \t  30  ',
      }
      local result = tabular.raw_parse(lines, '\t')

      eq(result.headers, { 'Name', 'Age' })
      eq(result.lines[1], { 'Alice', '30' })
    end)

    it('calculates correct column widths', function()
      local lines = {
        'A\tBB\tCCC',
        'AAAA\tB\tCC',
        'AA\tBBBB\tC',
      }
      local result = tabular.raw_parse(lines, '\t')

      eq(result.col_widths[1], 4) -- max of "A" (1) and "AAAA" (4)
      eq(result.col_widths[2], 4) -- max of "BB" (2) and "BBBB" (4)
      eq(result.col_widths[3], 3) -- max of "CCC" (3), "CC" (2), "C" (1)
    end)

    it('handles single column data', function()
      local lines = {
        'Name',
        'Alice',
        'Bob',
      }
      local result = tabular.raw_parse(lines, '\t')

      eq(result.headers, { 'Name' })
      eq(#result.lines, 2)
      eq(result.lines[1], { 'Alice' })
      eq(result.lines[2], { 'Bob' })
    end)

    it('handles empty values in cells', function()
      local lines = {
        'Name\tAge\tCity',
        'Alice\t\tNew York',
        '\t25\tLondon',
      }
      local result = tabular.raw_parse(lines, '\t')

      eq(result.headers, { 'Name', 'Age', 'City' })
      eq(result.lines[1], { 'Alice', 'New York' })
      eq(result.lines[2], { '25', 'London' })
    end)

    it('falls back to space delimiter when tab delimiter but no tabs found', function()
      local lines = {
        'Name  Age  City',
        'Alice  30  NYC',
      }
      local tab = vim.keycode '\t'
      local result = tabular.raw_parse(lines, tab)

      eq(result.headers, { 'Name', 'Age', 'City' })
      eq(result.lines[1], { 'Alice', '30', 'NYC' })
    end)

    it('handles special regex characters in delimiter', function()
      local lines = {
        'A.B.C',
        '1.2.3',
      }
      local result = tabular.raw_parse(lines, '.')

      eq(result.headers, { 'A', 'B', 'C' })
      eq(result.lines[1], { '1', '2', '3' })
    end)

    it('handles parentheses in delimiter', function()
      local lines = {
        'A(B(C',
        '1(2(3',
      }
      local result = tabular.raw_parse(lines, '(')

      eq(result.headers, { 'A', 'B', 'C' })
      eq(result.lines[1], { '1', '2', '3' })
    end)
  end)
end)
