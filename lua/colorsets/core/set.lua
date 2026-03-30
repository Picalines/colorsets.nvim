local Bimap = require 'colorsets.core.bimap'
local Group = require 'colorsets.core.group'

local inspect = vim.inspect

---@class ColorsetsSet
---@field modes ColorsetsReadonlyBimap<integer, ColorsetsMode>
---@field private _group_by_colorscheme table<ColorsetsColorscheme, ColorsetsGroup>
local Set = {}
Set.__index = Set

---@param modes ColorsetsMode[]
---@param groups table<ColorsetsMode, ColorsetsColorscheme>[]
---@return self
function Set.new(modes, groups)
  local set = setmetatable({
    modes = Bimap.array(modes),
    _group_by_colorscheme = {},
  }, Set)

  for _, group in ipairs(groups) do
    set:_add_group(group)
  end

  return set
end

---@param colorscheme ColorsetsColorscheme
---@return ColorsetsGroup|nil
function Set:group_of(colorscheme)
  return self._group_by_colorscheme[colorscheme]
end

---@private
---@param colorschemes table<ColorsetsMode, ColorsetsColorscheme>
function Set:_add_group(colorschemes)
  local group = Group.new(self, colorschemes)

  for _, colorscheme in pairs(colorschemes) do
    local existing_group = self:group_of(colorscheme)
    if existing_group ~= nil then
      error {
        code = 'set_duplicate_colorscheme',
        error = string.format(
          'colorscheme %s is already mapped',
          inspect(colorscheme)
        ),
      }
    end

    self._group_by_colorscheme[colorscheme] = group
  end
end

return Set
