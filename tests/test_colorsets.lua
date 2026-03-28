local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

---@param fn fun()
---@param code string
---@param error_value unknown
local function expect_error(fn, code, error_value)
  local ok, err = pcall(fn)
  local actual = assert(err, 'expected error')

  eq(ok, false)
  eq(actual.code, code)
  eq(actual.error, error_value)
end

---@param fn fun()
local function with_restored_test_state(fn)
  local original_colors_name = vim.g.colors_name
  local original_cmd = vim.cmd
  local original_colorsets = package.loaded.colorsets

  package.loaded.colorsets = nil

  local ok, err = pcall(fn)

  vim.g.colors_name = original_colors_name
  vim.cmd = original_cmd
  package.loaded.colorsets = original_colorsets

  if not ok then
    error(err)
  end
end

---@param load_colorscheme fun(colorscheme: string)
local function mock_vim_cmd_colorscheme(load_colorscheme)
  local original_cmd = vim.cmd

  vim.cmd = setmetatable({
    colorscheme = load_colorscheme,
  }, { __index = original_cmd })
end

---@return ColorsetsConfigPartial
local function daytime_config()
  return {
    sets = {
      daytime = {
        modes = { 'light', 'dark' },
        colorschemes = {
          {
            light = 'dayfox',
            dark = 'nightfox',
          },
          {
            light = 'perpetua-light',
            dark = 'perpetua-dark',
          },
        },
      },
    },
  }
end

local T = new_set()

T['colorsets'] = new_set()

T['colorsets']['setup'] = new_set()

T['colorsets']['setup']['creates switcher used by next'] = function()
  with_restored_test_state(function()
    local loaded
    local colorsets = require 'colorsets'

    vim.g.colors_name = 'dayfox'
    mock_vim_cmd_colorscheme(function(colorscheme)
      loaded = colorscheme
    end)

    colorsets.setup(daytime_config())
    colorsets.next 'daytime'

    eq(loaded, 'nightfox')
  end)
end

T['colorsets']['setup']['creates switcher used by prev'] = function()
  with_restored_test_state(function()
    local loaded
    local colorsets = require 'colorsets'

    vim.g.colors_name = 'perpetua-light'
    mock_vim_cmd_colorscheme(function(colorscheme)
      loaded = colorscheme
    end)

    colorsets.setup(daytime_config())
    colorsets.prev 'daytime'

    eq(loaded, 'perpetua-dark')
  end)
end

T['colorsets']['setup']['creates switcher used by set'] = function()
  with_restored_test_state(function()
    local loaded
    local colorsets = require 'colorsets'

    vim.g.colors_name = 'perpetua-light'
    mock_vim_cmd_colorscheme(function(colorscheme)
      loaded = colorscheme
    end)

    colorsets.setup(daytime_config())
    colorsets.set('daytime', 'dark')

    eq(loaded, 'perpetua-dark')
  end)
end

T['colorsets']['setup']['raises config errors while building sets'] = function()
  with_restored_test_state(function()
    local colorsets = require 'colorsets'

    expect_error(
      function()
        colorsets.setup {
          sets = {
            daytime = {
              modes = { 'light', 'dark' },
              colorschemes = {
                { light = 'dayfox', dark = 'nightfox' },
                { light = 'dayfox', dark = 'carbonfox' },
              },
            },
          },
        }
      end,
      'set_duplicate_colorscheme',
      'colorset "daytime": colorscheme "dayfox" is already mapped'
    )
  end)
end

T['colorsets']['public API'] = new_set()

T['colorsets']['public API']['errors before setup'] = function()
  with_restored_test_state(function()
    local colorsets = require 'colorsets'
    local ok, err = pcall(function()
      colorsets.next 'daytime'
    end)

    eq(ok, false)
    eq(
      type(err) == 'string' and err:match 'colorsets is not setup' ~= nil,
      true
    )
  end)
end

T['colorsets']['public API']['returns switcher errors without raising'] = function()
  with_restored_test_state(function()
    local colorsets = require 'colorsets'

    colorsets.setup(daytime_config())

    eq(colorsets.next 'contrast', {
      code = 'switcher_unknown_set',
      error = 'unknown colorset "contrast"',
    })
  end)
end

return T
