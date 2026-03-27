local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local err = MiniTest.expect.error
local no_err = MiniTest.expect.no_error

local Bimap = require 'colorsets.bimap'

local T = new_set()

T['bimap'] = new_set()

T['bimap']['stores pairs in both directions'] = function()
  ---@type ColorsetsBimap<string, string>
  local bimap = Bimap.new()

  eq(bimap.size, 0)

  bimap:add('dark', 'tokyonight')

  eq(bimap.size, 1)
  eq(bimap:value 'dark', 'tokyonight')
  eq(bimap:key 'tokyonight', 'dark')
end

T['bimap']['returns nil for missing entries'] = function()
  ---@type ColorsetsBimap<string, string>
  local bimap = Bimap.new()

  eq(bimap:value 'missing', nil)
  eq(bimap:key 'missing', nil)
end

T['bimap']['allows adding the same pair twice'] = function()
  ---@type ColorsetsBimap<string, string>
  local bimap = Bimap.new()

  bimap:add('dark', 'tokyonight')
  eq(bimap.size, 1)

  no_err(function()
    bimap:add('dark', 'tokyonight')
  end)

  eq(bimap.size, 1)
end

T['bimap']['errors on conflicting value for key'] = function()
  ---@type ColorsetsBimap<string, string>
  local bimap = Bimap.new()
  bimap:add('dark', 'tokyonight')

  err(function()
    bimap:add('dark', 'gruvbox')
  end, 'key "dark" is already mapped to value "tokyonight", got "gruvbox"')
end

T['bimap']['errors on conflicting key for value'] = function()
  ---@type ColorsetsBimap<string, string>
  local bimap = Bimap.new()
  bimap:add('dark', 'tokyonight')

  err(function()
    bimap:add('night', 'tokyonight')
  end, 'value "tokyonight" is already mapped to key "dark", got "night"')
end

T['bimap']['array builds index lookups'] = function()
  local bimap = Bimap.array { 'tokyonight', 'gruvbox', 'catppuccin' }

  eq(bimap.size, 3)
  eq(bimap:value(1), 'tokyonight')
  eq(bimap:value(2), 'gruvbox')
  eq(bimap:value(3), 'catppuccin')
  eq(bimap:key 'tokyonight', 1)
  eq(bimap:key 'gruvbox', 2)
  eq(bimap:key 'catppuccin', 3)
end

T['bimap']['array errors on duplicate values'] = function()
  err(function()
    Bimap.array { 'tokyonight', 'gruvbox', 'tokyonight' }
  end, 'value "tokyonight" is already mapped to key 1, got 3')
end

T['bimap']['table builds key lookups'] = function()
  local bimap = Bimap.table {
    dark = 'tokyonight',
    light = 'dayfox',
  }

  eq(bimap.size, 2)
  eq(bimap:value 'dark', 'tokyonight')
  eq(bimap:value 'light', 'dayfox')
  eq(bimap:key 'tokyonight', 'dark')
  eq(bimap:key 'dayfox', 'light')
end

T['bimap']['table errors on duplicate values'] = function()
  err(function()
    Bimap.table {
      dark = 'tokyonight',
      night = 'tokyonight',
    }
  end, 'value "tokyonight" is already mapped to key ".-", got ".-"')
end

return T
