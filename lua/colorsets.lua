---@brief [[
---colorsets.nvim
---@brief ]]

local M = {}

local Switcher = require 'colorsets.switcher'
local config = require 'colorsets.config'

---@type ColorsetsSwitcher|nil
local switcher

---@return ColorsetsSwitcher
local function get_switcher()
  return switcher or error 'colorsets is not setup'
end

---@param partial_config? ColorsetsConfigPartial
function M.setup(partial_config)
  local full_config = config.with_defaults(partial_config or {})
  local sets = config.create_sets(full_config.sets)
  switcher = Switcher.new {
    sets = sets,
    current_colorscheme = full_config.current_colorscheme,
    load_colorscheme = full_config.load_colorscheme,
  }
end

---@param set_name string
function M.next(set_name)
  return get_switcher():next(set_name)
end

---@param set_name string
function M.prev(set_name)
  return get_switcher():prev(set_name)
end

---@param set_name string
---@param mode ColorsetsMode
function M.set(set_name, mode)
  return get_switcher():set(set_name, mode)
end

return M
