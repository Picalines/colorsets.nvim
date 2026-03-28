local Set = require 'colorsets.core.set'

local inspect = vim.inspect

local M = {}

---@alias ColorsetsColorscheme string
---@alias ColorsetsMode string

---@alias ColorsetsConfigGroup table<ColorsetsMode, ColorsetsColorscheme>

---@class ColorsetsConfigSet
---@field modes ColorsetsMode[]
---@field colorschemes ColorsetsConfigGroup[]

---@class ColorsetsConfigCommand
---@field name string

---@class ColorsetsConfig
---@field sets table<string, ColorsetsConfigSet>
---@field command ColorsetsConfigCommand|false

---@class ColorsetsConfigPartial
---@field sets? table<string, ColorsetsConfigSet>
---@field command? ColorsetsConfigCommand|false

---@type ColorsetsConfig
local default_config = {
  sets = {},
  command = {
    name = 'Colorset',
  },
}

---@param partial_config ColorsetsConfigPartial
function M.with_defaults(partial_config)
  return vim.tbl_deep_extend('force', default_config, partial_config)
end

---@param err unknown
---@return ColorsetsError
local function normalize_error(err)
  if type(err) == 'table' then
    local code = err.code
    local error = err.error

    if type(code) == 'string' and type(error) == 'string' then
      return err
    end
  end

  return {
    code = 'config_set_creation_failed',
    error = tostring(err),
  }
end

---@private
---@param set_configs table<string, ColorsetsConfigSet>
---@return table<string, ColorsetsSet>
function M.create_sets(set_configs)
  local sets = {}

  for set_name, set_config in pairs(set_configs) do
    local ok, set = pcall(Set.new, set_config.modes, set_config.colorschemes)
    if not ok then
      local err = normalize_error(set)

      error {
        code = err.code,
        error = string.format('colorset %s: %s', inspect(set_name), err.error),
      }
    end

    sets[set_name] = set
  end

  return sets
end

return M
