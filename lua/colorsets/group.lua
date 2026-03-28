local Bimap = require 'colorsets.bimap'

local inspect = vim.inspect

---@param index integer
---@param offset integer
---@param size integer
---@return integer
local function wrapped_index(index, offset, size)
  return ((index - 1 + offset) % size) + 1
end

---@class ColorsetsGroup
---@field set ColorsetsSet
---@field colorschemes ColorsetsReadonlyBimap<ColorsetsMode, ColorsetsColorscheme>
local Group = {}
Group.__index = Group

---@param set ColorsetsSet
---@param colorschemes table<ColorsetsMode, ColorsetsColorscheme>
function Group.new(set, colorschemes)
  for mode in pairs(colorschemes) do
    if set.modes:key(mode) == nil then
      error(string.format('group has unknown mode %s', inspect(mode)))
    end
  end

  for index = 1, set.modes.size do
    local mode = set.modes:value(index)
    if colorschemes[mode] == nil then
      error(string.format('group is missing mode %s', inspect(mode)))
    end
  end

  return setmetatable({
    set = set,
    colorschemes = Bimap.table(colorschemes),
  }, Group)
end

---@param colorscheme ColorsetsColorscheme
---@return ColorsetsMode|nil
function Group:mode(colorscheme)
  return self.colorschemes:key(colorscheme)
end

---@param mode ColorsetsMode
---@return ColorsetsColorscheme|nil
function Group:colorscheme(mode)
  return self.colorschemes:value(mode)
end

---@class ColorsetsGroupEntry
---@field colorscheme ColorsetsColorscheme
---@field mode ColorsetsMode

---@param colorscheme ColorsetsColorscheme
---@return ColorsetsGroupEntry|nil
function Group:next_of(colorscheme)
  return self:_move_from(colorscheme, 1)
end

---@param colorscheme ColorsetsColorscheme
---@return ColorsetsGroupEntry|nil
function Group:prev_of(colorscheme)
  return self:_move_from(colorscheme, -1)
end

---@param colorscheme ColorsetsColorscheme
---@param offset integer
---@return ColorsetsGroupEntry|nil
---@private
function Group:_move_from(colorscheme, offset)
  local current_mode = self:mode(colorscheme)
  if current_mode == nil then
    return nil
  end

  local current_mode_index = self.set.modes:key(current_mode)
  if current_mode_index == nil then
    return nil
  end

  local target_mode = self.set.modes:value(
    wrapped_index(current_mode_index, offset, self.set.modes.size)
  )

  if target_mode == nil then
    return nil
  end

  local target_colorscheme = self:colorscheme(target_mode)
  if target_colorscheme == nil then
    return nil
  end

  return {
    colorscheme = target_colorscheme,
    mode = target_mode,
  }
end

return Group
