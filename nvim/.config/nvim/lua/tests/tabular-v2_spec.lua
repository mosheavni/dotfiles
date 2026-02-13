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

  describe('parse_size', function()
    it('parses binary IEC suffixes (Ki, Mi, Gi, Ti, Pi)', function()
      eq(tabular.parse_size '1Ki', 1024)
      eq(tabular.parse_size '1Mi', 1024 ^ 2)
      eq(tabular.parse_size '1Gi', 1024 ^ 3)
      eq(tabular.parse_size '1Ti', 1024 ^ 4)
      eq(tabular.parse_size '1Pi', 1024 ^ 5)
    end)

    it('parses long binary suffixes (KiB, MiB, GiB, TiB, PiB)', function()
      eq(tabular.parse_size '1KiB', 1024)
      eq(tabular.parse_size '1MiB', 1024 ^ 2)
      eq(tabular.parse_size '1GiB', 1024 ^ 3)
      eq(tabular.parse_size '1TiB', 1024 ^ 4)
      eq(tabular.parse_size '1PiB', 1024 ^ 5)
    end)

    it('parses decimal SI suffixes (K, M, G, T, P)', function()
      eq(tabular.parse_size '1K', 1000)
      eq(tabular.parse_size '1M', 1000 ^ 2)
      eq(tabular.parse_size '1G', 1000 ^ 3)
      eq(tabular.parse_size '1T', 1000 ^ 4)
      eq(tabular.parse_size '1P', 1000 ^ 5)
    end)

    it('parses decimal suffixes with B (KB, MB, GB, TB, PB)', function()
      eq(tabular.parse_size '1KB', 1000)
      eq(tabular.parse_size '1MB', 1000 ^ 2)
      eq(tabular.parse_size '1GB', 1000 ^ 3)
      eq(tabular.parse_size '1TB', 1000 ^ 4)
      eq(tabular.parse_size '1PB', 1000 ^ 5)
    end)

    it('parses plain bytes', function()
      eq(tabular.parse_size '512B', 512)
    end)

    it('parses decimal numbers', function()
      eq(tabular.parse_size '2.5Gi', 2.5 * 1024 ^ 3)
      eq(tabular.parse_size '1.5MB', 1.5 * 1000 ^ 2)
    end)

    it('parses values with space before suffix', function()
      eq(tabular.parse_size '100 Mi', 100 * 1024 ^ 2)
      eq(tabular.parse_size '5 GB', 5 * 1000 ^ 3)
    end)

    it('returns nil for non-size strings', function()
      eq(tabular.parse_size 'hello', nil)
      eq(tabular.parse_size '', nil)
      eq(tabular.parse_size '123', nil)
      eq(tabular.parse_size 'abc123', nil)
    end)

    it('returns nil for unknown suffixes', function()
      eq(tabular.parse_size '5X', nil)
      eq(tabular.parse_size '10ZZ', nil)
    end)
  end)
end)
