local M = {}

local config = require 'colorsets.config'

---@brief [[
---colorsets.nvim
---@brief ]]

---@param partial_config ColorsetsConfigPartial
function M.setup(partial_config)
  local full_config = config.with_defaults(partial_config)
end

return M
