---@diagnostic disable: invisible
---@toc colorsets.contents
---@mod colorsets colorsets.nvim
---@brief [[
---Stateless colorscheme switcher for Neovim.
---
---Define named sets of related colorschemes and switch within a set without
---losing the current group. Use it from Lua or through the built-in
---`:Colorset` command.
---@brief ]]

---@tag colorsets.nvim

---@package
---@class ColorsetsError
---@field code string
---@field error unknown

local M = {}

local Switcher = require 'colorsets.core.switcher'
local config = require 'colorsets.config'
local user_command = require 'colorsets.user_command'

---@type ColorsetsSwitcher|nil
local switcher

---@return ColorsetsSwitcher
local function get_switcher()
  return switcher or error 'colorsets is not setup'
end

---@mod colorsets.setup Setup

---Configure `colorsets.nvim`.
---
---Call this once during startup to define your colorsets, optionally rename or
---disable the user command, and override how the current colorscheme is read
---or applied.
---@param partial_config? ColorsetsConfigPartial Partial plugin config.
---@usage lua [[
---require('colorsets').setup {
---  sets = {
---    daytime = {
---      modes = { 'light', 'dark' },
---      colorschemes = {
---        { light = 'dayfox', dark = 'nightfox' },
---      },
---    },
---  },
---}
---@usage ]]
function M.setup(partial_config)
  local full_config = config.with_defaults(partial_config or {})
  local sets = config.create_sets(full_config.sets)
  switcher = Switcher.new {
    sets = sets,
    current_colorscheme = full_config.current_colorscheme,
    load_colorscheme = full_config.load_colorscheme,
  }

  user_command.create(switcher, full_config.command)
end

---@mod colorsets.dynamic Dynamic colorschemes
---@brief [[
---Some Neovim colorschemes are dynamic and build their palette from external
---state like `'background'`, global variables, or other setup code. In those
---cases it is often simpler to create a small wrapper colorscheme which fixes
---that state first and then exposes its own stable `g:colors_name`.
---
---For example, `mini.hues` bundled colorschemes read `'background'` while
---loading. This wrapper creates a fixed dark variant named `miniwinter-dark`:
--->vim
---  " ~/.config/nvim/colors/miniwinter-dark.vim
---  set background=dark
---  runtime colors/miniwinter.lua
---  let g:colors_name = 'miniwinter-dark'
---<
---
---This file makes `miniwinter-dark` a valid option for the `:colorscheme`
---command, so you can include it in a colorset just like any other
---colorscheme.
---@brief ]]

---@mod colorsets.api Lua API

---Switch a set to the next mode in the current group.
---@param set_name string Colorset name.
---@usage `require('colorsets').next 'daytime'`
function M.next(set_name)
  return get_switcher():next(set_name)
end

---Switch a set to the previous mode in the current group.
---@param set_name string Colorset name.
---@usage `require('colorsets').prev 'daytime'`
function M.prev(set_name)
  return get_switcher():prev(set_name)
end

---Switch a set to a specific mode.
---@param set_name string Colorset name.
---@param mode ColorsetsMode Target mode name.
---@usage `require('colorsets').set('daytime', 'dark')`
function M.set(set_name, mode)
  return get_switcher():set(set_name, mode)
end

return M
