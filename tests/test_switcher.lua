local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local Set = require 'colorsets.core.set'
local Switcher = require 'colorsets.switcher'

---@param err ColorsetsSwitcherError|nil
---@param code string
---@param error_value unknown
local function expect_error(err, code, error_value)
  local actual = assert(err, 'expected error')

  eq(type(actual), 'table')
  eq(actual.code, code)
  eq(actual.error, error_value)
end

---@return ColorsetsSet
local function new_daytime_set()
  return Set.new({ 'light', 'dark' }, {
    {
      light = 'dayfox',
      dark = 'nightfox',
    },
    {
      light = 'perpetua-light',
      dark = 'perpetua-dark',
    },
  })
end

---@class ColorsetsSwitcherTestOptions
---@field sets? table<string, ColorsetsSet>
---@field current? string
---@field current_colorscheme? fun(): unknown
---@field load_colorscheme? fun(colorscheme: string)

---@param opts? ColorsetsSwitcherTestOptions
---@return ColorsetsSwitcher
---@return string[]
---@return fun(colorscheme: string)
local function new_switcher(opts)
  opts = opts or {}

  local current = opts.current or 'dayfox'
  local loaded = {}

  local switcher = Switcher.new {
    sets = opts.sets or { daytime = new_daytime_set() },
    current_colorscheme = opts.current_colorscheme or function()
      return current
    end,
    load_colorscheme = opts.load_colorscheme or function(colorscheme)
      table.insert(loaded, colorscheme)
    end,
  }

  return switcher, loaded, function(colorscheme)
    current = colorscheme
  end
end

local T = new_set()

T['switcher'] = new_set()

T['switcher']['next'] = new_set()

T['switcher']['next']['loads next colorscheme from current group'] = function()
  local switcher, loaded = new_switcher { current = 'dayfox' }

  eq(switcher:next 'daytime', nil)
  eq(loaded, { 'nightfox' })
end

T['switcher']['next']['wraps within the current group'] = function()
  local switcher, loaded = new_switcher { current = 'perpetua-dark' }

  eq(switcher:next 'daytime', nil)
  eq(loaded, { 'perpetua-light' })
end

T['switcher']['next']['returns error for unknown set'] = function()
  local switcher = new_switcher()

  expect_error(
    switcher:next 'contrast',
    'switcher_unknown_set',
    'unknown colorset "contrast"'
  )
end

T['switcher']['next']['returns error when current colorscheme lookup fails'] = function()
  local failure = { message = 'boom' }
  local switcher = new_switcher {
    current_colorscheme = function()
      error(failure)
    end,
  }

  expect_error(
    switcher:next 'daytime',
    'switcher_get_current_colorscheme_failed',
    failure
  )
end

T['switcher']['next']['returns error for invalid current colorscheme'] = function()
  local switcher = new_switcher {
    current_colorscheme = function()
      return false
    end,
  }

  expect_error(
    switcher:next 'daytime',
    'switcher_invalid_current_colorscheme',
    'current colorscheme must be a string, got false'
  )
end

T['switcher']['next']['returns error when current colorscheme is outside the set'] = function()
  local switcher = new_switcher { current = 'gruvbox' }

  expect_error(
    switcher:next 'daytime',
    'switcher_colorscheme_outside_set',
    'current colorscheme "gruvbox" is not in colorset "daytime"'
  )
end

T['switcher']['next']['returns error when colorscheme loading fails'] = function()
  local failure = { message = 'cannot load' }
  local switcher = new_switcher {
    load_colorscheme = function()
      error(failure)
    end,
  }

  expect_error(
    switcher:next 'daytime',
    'switcher_load_colorscheme_failed',
    failure
  )
end

T['switcher']['next']['does not load when target matches current'] = function()
  local switcher, loaded = new_switcher {
    current = 'only-theme',
    sets = {
      single = Set.new({ 'only' }, { { only = 'only-theme' } }),
    },
  }

  eq(switcher:next 'single', nil)
  eq(loaded, {})
end

T['switcher']['prev'] = new_set()

T['switcher']['prev']['loads previous colorscheme from current group'] = function()
  local switcher, loaded = new_switcher { current = 'dayfox' }

  eq(switcher:prev 'daytime', nil)
  eq(loaded, { 'nightfox' })
end

T['switcher']['set'] = new_set()

T['switcher']['set']['loads requested mode from current group'] = function()
  local switcher, loaded = new_switcher { current = 'perpetua-light' }

  eq(switcher:set('daytime', 'dark'), nil)
  eq(loaded, { 'perpetua-dark' })
end

T['switcher']['set']['returns error for unknown mode'] = function()
  local switcher = new_switcher()

  expect_error(
    switcher:set('daytime', 'high'),
    'switcher_unknown_mode',
    'unknown mode "high" for colorset "daytime"'
  )
end

T['switcher']['set']['does not load when mode matches current'] = function()
  local switcher, loaded = new_switcher { current = 'nightfox' }

  eq(switcher:set('daytime', 'dark'), nil)
  eq(loaded, {})
end

return T
