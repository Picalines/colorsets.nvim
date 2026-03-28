---@brief [[
---colorsets.nvim
---@brief ]]

local M = {}

local Switcher = require 'colorsets.switcher'
local config = require 'colorsets.config'

---@type ColorsetsSwithcer|nil
local switcher

---@return ColorsetsSwithcer
local function get_switcher()
  return switcher or error 'colorsets is not setup'
end

---@param partial_config? ColorsetsConfigPartial
function M.setup(partial_config)
  local full_config = config.with_defaults(partial_config or {})
  local sets = config.create_sets(full_config.sets)
  switcher = Switcher.new { sets = sets }
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
