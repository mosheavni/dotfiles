local status_ok, neoscroll = pcall(require, "neoscroll")
if not status_ok then
  return
end

-- neoscroll
neoscroll.setup({
  -- All these keys will be mapped to their corresponding default scrolling animation
  mappings = { '<C-u>', '<C-d>', 'zt', 'zz', 'zb' }
})
