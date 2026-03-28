local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality

local Set = require 'colorsets.core.set'

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

T['set'] = new_set()

T['set']['new'] = new_set()

T['set']['new']['stores group lookups by colorscheme'] = function()
  local set = Set.new({ 'light', 'dark' }, {
    {
      light = 'dayfox',
      dark = 'nightfox',
    },
  })

  local group = assert(set:group_of 'dayfox', 'expected group for dayfox')

  eq(group, set:group_of 'nightfox')
  eq(group:colorscheme 'light', 'dayfox')
  eq(group:colorscheme 'dark', 'nightfox')
end

T['set']['new']['stores multiple groups'] = function()
  local set = Set.new({ 'light', 'dark' }, {
    {
      light = 'dayfox',
      dark = 'nightfox',
    },
    {
      light = 'perpetua-light',
      dark = 'perpetua-dark',
    },
  })

  local first_group = assert(set:group_of 'dayfox', 'expected group for dayfox')
  local second_group = assert(
    set:group_of 'perpetua-light',
    'expected group for perpetua-light'
  )

  eq(set:group_of 'nightfox', first_group)
  eq(set:group_of 'perpetua-dark', second_group)
  neq(first_group, second_group)
end

T['set']['new']['errors on duplicate colorscheme in set'] = function()
  expect_error(function()
    Set.new({ 'light', 'dark' }, {
      {
        light = 'dayfox',
        dark = 'nightfox',
      },
      {
        light = 'dayfox',
        dark = 'carbonfox',
      },
    })
  end, 'set_duplicate_colorscheme', 'colorscheme "dayfox" is already mapped')
end

T['set']['group_of'] = new_set()

T['set']['group_of']['returns nil for colorscheme outside the set'] = function()
  local set = Set.new({ 'light', 'dark' }, {
    {
      light = 'dayfox',
      dark = 'nightfox',
    },
  })

  eq(set:group_of 'gruvbox', nil)
end

return T
