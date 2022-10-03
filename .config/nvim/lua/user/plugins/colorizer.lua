---------------
-- Colorizer --
---------------
local status_ok_colorizer, colorizer = pcall(require, 'colorizer')
if not status_ok_colorizer then
  return
end
colorizer.setup()
