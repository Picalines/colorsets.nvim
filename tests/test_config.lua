local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality

local config = require 'colorsets.config'

---@param fn fun()
---@param code string
---@param error_message string
local function expect_error(fn, code, error_message)
  local ok, err = pcall(fn)

  eq(ok, false)
  eq(err.code, code)
  eq(err.error, error_message)
end

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

T['config']['create_sets'] = new_set()

T['config']['create_sets']['creates sets from config map'] = function()
  local sets = config.create_sets {
    daytime = {
      modes = { 'light', 'dark' },
      colorschemes = {
        {
          light = 'dayfox',
          dark = 'nightfox',
        },
      },
    },
    contrast = {
      modes = { 'low', 'mid', 'high' },
      colorschemes = {
        {
          low = 'terafox',
          mid = 'duskfox',
          high = 'carbonfox',
        },
      },
    },
  }

  local daytime = assert(sets.daytime, 'expected daytime set')
  local contrast = assert(sets.contrast, 'expected contrast set')

  eq(daytime.modes:value(1), 'light')
  eq(daytime.modes:value(2), 'dark')
  eq(daytime:group_of 'dayfox', daytime:group_of 'nightfox')

  eq(contrast.modes:value(1), 'low')
  eq(contrast.modes:value(2), 'mid')
  eq(contrast.modes:value(3), 'high')
  eq(contrast:group_of 'terafox', contrast:group_of 'carbonfox')

  neq(daytime, contrast)
end

T['config']['create_sets']['prefixes set name in set construction errors'] = function()
  expect_error(function()
    config.create_sets {
      daytime = {
        modes = { 'light', 'dark' },
        colorschemes = {
          {
            light = 'dayfox',
            dark = 'nightfox',
          },
          {
            light = 'dayfox',
            dark = 'carbonfox',
          },
        },
      },
    }
  end,
  'set_duplicate_colorscheme',
  'colorset "daytime": colorscheme "dayfox" is already mapped')
end

return T
