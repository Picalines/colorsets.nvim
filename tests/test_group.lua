local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local err = MiniTest.expect.error

local Group = require 'colorsets.core.group'
local Set = require 'colorsets.core.set'

local T = new_set()

T['group'] = new_set()

T['group']['stores mode to colorscheme mappings'] = function()
  local set = Set.new({ 'light', 'dark' }, {})
  local group = Group.new(set, {
    light = 'dayfox',
    dark = 'nightfox',
  })

  eq(group:mode 'dayfox', 'light')
  eq(group:mode 'nightfox', 'dark')
  eq(group:colorscheme 'light', 'dayfox')
  eq(group:colorscheme 'dark', 'nightfox')
end

T['group']['errors on unknown mode in config'] = function()
  local set = Set.new({ 'light', 'dark' }, {})

  err(function()
    Group.new(set, {
      light = 'dayfox',
      high = 'carbonfox',
    })
  end, 'group has unknown mode "high"')
end

T['group']['errors on missing mode in config'] = function()
  local set = Set.new({ 'light', 'dark' }, {})

  err(function()
    Group.new(set, {
      light = 'dayfox',
    })
  end, 'group is missing mode "dark"')
end

T['group']['next_of'] = new_set()

T['group']['next_of']['wraps to the first mode'] = function()
  local set = Set.new({ 'light', 'dark' }, {})
  local group = Group.new(set, {
    light = 'dayfox',
    dark = 'nightfox',
  })

  eq(group:next_of 'dayfox', { colorscheme = 'nightfox', mode = 'dark' })
  eq(group:next_of 'nightfox', { colorscheme = 'dayfox', mode = 'light' })
end

T['group']['next_of']['moves through three modes'] = function()
  local set = Set.new({ 'low', 'mid', 'high' }, {})
  local group = Group.new(set, {
    low = 'terafox',
    mid = 'duskfox',
    high = 'carbonfox',
  })

  eq(group:next_of 'terafox', { colorscheme = 'duskfox', mode = 'mid' })
  eq(group:next_of 'duskfox', { colorscheme = 'carbonfox', mode = 'high' })
  eq(group:next_of 'carbonfox', { colorscheme = 'terafox', mode = 'low' })
end

T['group']['next_of']['returns nil when colorscheme is outside the group'] = function()
  local set = Set.new({ 'light', 'dark' }, {})
  local group = Group.new(set, {
    light = 'dayfox',
    dark = 'nightfox',
  })

  eq(group:next_of 'gruvbox', nil)
end

T['group']['prev_of'] = new_set()

T['group']['prev_of']['wraps to the last mode'] = function()
  local set = Set.new({ 'light', 'dark' }, {})
  local group = Group.new(set, {
    light = 'dayfox',
    dark = 'nightfox',
  })

  eq(group:prev_of 'dayfox', { colorscheme = 'nightfox', mode = 'dark' })
  eq(group:prev_of 'nightfox', { colorscheme = 'dayfox', mode = 'light' })
end

T['group']['prev_of']['moves through three modes'] = function()
  local set = Set.new({ 'low', 'mid', 'high' }, {})
  local group = Group.new(set, {
    low = 'terafox',
    mid = 'duskfox',
    high = 'carbonfox',
  })

  eq(group:prev_of 'terafox', { colorscheme = 'carbonfox', mode = 'high' })
  eq(group:prev_of 'carbonfox', { colorscheme = 'duskfox', mode = 'mid' })
  eq(group:prev_of 'duskfox', { colorscheme = 'terafox', mode = 'low' })
end

T['group']['prev_of']['returns nil when colorscheme is outside the group'] = function()
  local set = Set.new({ 'light', 'dark' }, {})
  local group = Group.new(set, {
    light = 'dayfox',
    dark = 'nightfox',
  })

  eq(group:prev_of 'gruvbox', nil)
end

return T
