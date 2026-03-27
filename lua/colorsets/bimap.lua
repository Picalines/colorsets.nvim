---@class ColorsetsReadonlyBimap<K, V>
---@field size integer
---@field value fun(self: ColorsetsReadonlyBimap<K, V>, key: K): V|nil
---@field key fun(self: ColorsetsReadonlyBimap<K, V>, value: V): K|nil

---@class ColorsetsBimap<K, V>: ColorsetsReadonlyBimap<K, V>
---@field private _key_to_value table<K, V>
---@field private _value_to_key table<V, K>
local Bimap = {}
Bimap.__index = Bimap

local inspect = vim.inspect

---@generic K, V
---@return ColorsetsBimap<K, V>
function Bimap.new()
  return setmetatable({
    size = 0,
    _key_to_value = {},
    _value_to_key = {},
  }, Bimap)
end

---@generic T
---@param array T[]
---@return ColorsetsBimap<integer, T>
function Bimap.array(array)
  ---@type ColorsetsBimap<integer, any>
  local bimap = Bimap.new()
  for index, item in ipairs(array) do
    bimap:add(index, item)
  end
  return bimap
end

---@generic K, V
---@param values table<K, V>
---@return ColorsetsBimap<K, V>
function Bimap.table(values)
  ---@type ColorsetsBimap<any, any>
  local bimap = Bimap.new()
  for key, value in pairs(values) do
    bimap:add(key, value)
  end
  return bimap
end

---@param key K
---@param value V
function Bimap:add(key, value)
  local existing_value = self._key_to_value[key]
  if existing_value ~= nil and existing_value ~= value then
    error(
      string.format(
        'key %s is already mapped to value %s, got %s',
        inspect(key),
        inspect(existing_value),
        inspect(value)
      )
    )
  end

  local existing_key = self._value_to_key[value]
  if existing_key ~= nil and existing_key ~= key then
    error(
      string.format(
        'value %s is already mapped to key %s, got %s',
        inspect(value),
        inspect(existing_key),
        inspect(key)
      )
    )
  end

  if existing_value == nil then
    self.size = self.size + 1
  end

  self._key_to_value[key] = value
  self._value_to_key[value] = key
end

---@param key K
---@return V|nil
function Bimap:value(key)
  return self._key_to_value[key]
end

---@param value V
---@return K|nil
function Bimap:key(value)
  return self._value_to_key[value]
end

return Bimap
