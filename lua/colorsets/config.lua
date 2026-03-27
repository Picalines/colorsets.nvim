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

return M
