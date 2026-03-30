---@mod colorsets.config Config

---Colorscheme name used inside a colorset group.
---@alias ColorsetsColorscheme string

---Mode name used to address one variant inside a set.
---@alias ColorsetsMode string

---Mapping from mode name to colorscheme name for one group.
---@alias ColorsetsConfigGroup table<ColorsetsMode, ColorsetsColorscheme>

---One named colorset definition passed to `setup().sets`.
---@class ColorsetsConfigSet
---@field modes ColorsetsMode[]
---@field colorschemes ColorsetsConfigGroup[]

---Configuration for the generated user command.
---@class ColorsetsConfigCommand
---@field name string

---Metadata about the target colorset passed to `load_colorscheme`.
---@class ColorsetsLoadColorset
---@field name string
---@field mode ColorsetsMode

---Full plugin configuration after defaults are applied.
---@class ColorsetsConfig
---@field sets table<string, ColorsetsConfigSet>
---@field command ColorsetsConfigCommand|false
---@field current_colorscheme fun(): string
---@field load_colorscheme fun(colorscheme: string, colorset: ColorsetsLoadColorset)

---Configuration accepted by `require('colorsets').setup()`.
---@class ColorsetsConfigPartial
---@field sets? table<string, ColorsetsConfigSet>
---@field command? ColorsetsConfigCommand|false
---@field current_colorscheme? fun(): string
---@field load_colorscheme? fun(colorscheme: string, colorset: ColorsetsLoadColorset)

---@mod colorsets.hooks Hooks
---@brief [[
---Examples for config hooks passed to `setup()`.
---
---`current_colorscheme` returns the active colorscheme name:
--->lua
---  require('colorsets').setup {
---    current_colorscheme = function()
---      return vim.g.colors_name
---    end,
---  }
---<
---
---`load_colorscheme` applies a colorscheme by name:
--->lua
---  require('colorsets').setup {
---    load_colorscheme = function(colorscheme, colorset)
---      -- `colorset` contains `{ name = '...', mode = '...' }`
---      vim.cmd.colorscheme(colorscheme)
---    end,
---  }
---<
---@brief ]]

local Set = require 'colorsets.core.set'

local inspect = vim.inspect

local M = {}

---@type ColorsetsConfig
local default_config = {
  sets = {},
  command = {
    name = 'Colorset',
  },
  current_colorscheme = function()
    local colorscheme = vim.g.colors_name
    if type(colorscheme) ~= 'string' then
      error 'current colorscheme (g:colors_name) is not a string'
    end
    return colorscheme
  end,
  load_colorscheme = function(colorscheme)
    vim.cmd.colorscheme(colorscheme)
  end,
}

---@private
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
