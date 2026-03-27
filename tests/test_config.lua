local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local config = require 'colorsets.config'

local T = new_set()

T['config'] = new_set()

T['config']['empty sets by default'] = function()
  local full_config = config.with_defaults {}
  eq(full_config.sets, {})
end

T['config']['enables command by default'] = function()
  local full_config = config.with_defaults {}
  eq(full_config.command, { name = 'Colorset' })
end

T['config']['allows disabling the command'] = function()
  local full_config = config.with_defaults { command = false }
  eq(full_config.command, false)
end

return T
