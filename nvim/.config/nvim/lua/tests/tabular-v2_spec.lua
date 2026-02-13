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

  describe('parse_ip', function()
    it('parses dotted IP addresses', function()
      eq(tabular.parse_ip '10.10.42.1', { 10, 10, 42, 1 })
      eq(tabular.parse_ip '192.168.1.100', { 192, 168, 1, 100 })
      eq(tabular.parse_ip '0.0.0.0', { 0, 0, 0, 0 })
      eq(tabular.parse_ip '255.255.255.255', { 255, 255, 255, 255 })
    end)

    it('parses EC2 internal hostnames', function()
      eq(tabular.parse_ip 'ip-10-10-42-1.ec2.internal', { 10, 10, 42, 1 })
      eq(tabular.parse_ip 'ip-10-10-101-214.ec2.internal', { 10, 10, 101, 214 })
      eq(tabular.parse_ip 'ip-10-10-72-124.ec2.internal', { 10, 10, 72, 124 })
      eq(tabular.parse_ip 'ip-172-31-0-5.ec2.internal', { 172, 31, 0, 5 })
    end)

    it('parses bare EC2 dash-separated IPs without domain', function()
      eq(tabular.parse_ip 'ip-10-10-42-1', { 10, 10, 42, 1 })
    end)

    it('parses IP embedded in a larger string', function()
      eq(tabular.parse_ip 'server-192.168.1.1', { 192, 168, 1, 1 })
    end)

    it('returns nil for non-IP strings', function()
      eq(tabular.parse_ip 'hello', nil)
      eq(tabular.parse_ip '', nil)
      eq(tabular.parse_ip '123', nil)
      eq(tabular.parse_ip 'not-an-ip', nil)
    end)

    it('returns nil for invalid octet values', function()
      eq(tabular.parse_ip '256.1.1.1', nil)
      eq(tabular.parse_ip 'ip-999-10-10-1.ec2.internal', nil)
    end)
  end)

  describe('delete_displayed_lines', function()
    local fake_bufnr = 999

    local function setup_tab_state(lines, display_indices)
      local tab_state = vim.tbl_deep_extend('force', {}, tabular.default_tab_state, {
        bufnr = fake_bufnr,
        command = 'test-delete',
        lines = lines,
        display_indices = display_indices,
        headers = { 'Name', 'Age' },
        col_widths = { 4, 3 },
      })
      tabular.tabs_state['test-delete'] = tab_state
      return tab_state
    end

    after_each(function()
      tabular.tabs_state['test-delete'] = nil
    end)

    it('removes a single line with dd (buffer line 3 = display index 1)', function()
      local tab_state = setup_tab_state({
        { 'Alice', '30' },
        { 'Bob', '25' },
        { 'Charlie', '35' },
      }, { 1, 2, 3 })

      -- Simulate dd on buffer line 3 (first data line)
      -- delete_displayed_lines maps buffer line 3 → display_indices[1] = data index 1
      tabular.delete_displayed_lines(fake_bufnr, 3, 3)

      eq(#tab_state.lines, 2)
      eq(tab_state.lines[1], { 'Bob', '25' })
      eq(tab_state.lines[2], { 'Charlie', '35' })
    end)

    it('removes multiple lines (e.g. d2j from line 3 to 5)', function()
      local tab_state = setup_tab_state({
        { 'Alice', '30' },
        { 'Bob', '25' },
        { 'Charlie', '35' },
        { 'Dave', '40' },
      }, { 1, 2, 3, 4 })

      tabular.delete_displayed_lines(fake_bufnr, 3, 5)

      eq(#tab_state.lines, 1)
      eq(tab_state.lines[1], { 'Dave', '40' })
    end)

    it('removes the last line', function()
      local tab_state = setup_tab_state({
        { 'Alice', '30' },
        { 'Bob', '25' },
      }, { 1, 2 })

      tabular.delete_displayed_lines(fake_bufnr, 4, 4)

      eq(#tab_state.lines, 1)
      eq(tab_state.lines[1], { 'Alice', '30' })
    end)

    it('respects display_indices with active filter', function()
      -- lines has 4 entries, but filter only shows indices 1, 3, 4
      local tab_state = setup_tab_state({
        { 'Alice', '30' },
        { 'Bob', '25' },
        { 'Charlie', '35' },
        { 'Dave', '40' },
      }, { 1, 3, 4 })

      -- Delete buffer line 4 → display_indices[2] = data index 3 (Charlie)
      tabular.delete_displayed_lines(fake_bufnr, 4, 4)

      eq(#tab_state.lines, 3)
      eq(tab_state.lines[1], { 'Alice', '30' })
      eq(tab_state.lines[2], { 'Bob', '25' })
      eq(tab_state.lines[3], { 'Dave', '40' })
    end)

    it('clamps start_line to 3 (skips header and separator)', function()
      local tab_state = setup_tab_state({
        { 'Alice', '30' },
        { 'Bob', '25' },
      }, { 1, 2 })

      -- Range includes header lines 1-3, should only delete data at line 3
      tabular.delete_displayed_lines(fake_bufnr, 1, 3)

      eq(#tab_state.lines, 1)
      eq(tab_state.lines[1], { 'Bob', '25' })
    end)

    it('does nothing when range is entirely in header area', function()
      local tab_state = setup_tab_state({
        { 'Alice', '30' },
      }, { 1 })

      tabular.delete_displayed_lines(fake_bufnr, 1, 2)

      eq(#tab_state.lines, 1)
      eq(tab_state.lines[1], { 'Alice', '30' })
    end)

    it('does nothing for unknown bufnr', function()
      setup_tab_state({
        { 'Alice', '30' },
      }, { 1 })

      -- Should not error
      tabular.delete_displayed_lines(12345, 3, 3)
    end)
  end)

  describe('compare_ips', function()
    it('compares IPs by first differing octet', function()
      eq(tabular.compare_ips({ 10, 10, 42, 1 }, { 10, 10, 101, 214 }), -1)
      eq(tabular.compare_ips({ 10, 10, 101, 214 }, { 10, 10, 42, 1 }), 1)
    end)

    it('returns 0 for equal IPs', function()
      eq(tabular.compare_ips({ 10, 10, 42, 1 }, { 10, 10, 42, 1 }), 0)
    end)

    it('compares by later octets when earlier ones are equal', function()
      eq(tabular.compare_ips({ 10, 10, 10, 1 }, { 10, 10, 10, 2 }), -1)
      eq(tabular.compare_ips({ 10, 10, 10, 255 }, { 10, 10, 10, 1 }), 1)
    end)

    it('compares by first octet correctly', function()
      eq(tabular.compare_ips({ 10, 0, 0, 0 }, { 172, 0, 0, 0 }), -1)
      eq(tabular.compare_ips({ 192, 168, 1, 1 }, { 10, 0, 0, 1 }), 1)
    end)
  end)
end)
