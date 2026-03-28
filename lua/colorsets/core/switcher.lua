local inspect = vim.inspect

---@class ColorsetsSwitcher
---@field private _sets table<string, ColorsetsSet>
---@field private _set_names string[]
---@field private _get_current_colorscheme fun(): string
---@field private _load_colorscheme fun(colorscheme: string)
local Switcher = {}
Switcher.__index = Switcher

---@class ColorsetsSwitcherConfig
---@field sets table<string, ColorsetsSet>
---@field current_colorscheme fun(): string
---@field load_colorscheme fun(colorscheme: string)

---@param config ColorsetsSwitcherConfig
---@return ColorsetsSwitcher
function Switcher.new(config)
  local set_names = vim.tbl_keys(config.sets)
  table.sort(set_names)

  return setmetatable({
    _sets = config.sets,
    _set_names = set_names,
    _get_current_colorscheme = config.current_colorscheme,
    _load_colorscheme = config.load_colorscheme,
  }, Switcher)
end

---@return string[]
function Switcher:set_names()
  return self._set_names
end

---@param set_name string
---@return ColorsetsMode[]|nil
function Switcher:modes_of(set_name)
  local set = self._sets[set_name]
  if set == nil then
    return nil
  end
  return set.modes:values()
end

---@param set_name string
---@return ColorsetsSet|nil
---@return ColorsetsError|nil
---@private
function Switcher:_set_by_name(set_name)
  local set = self._sets[set_name]
  if set == nil then
    return nil,
      {
        code = 'switcher_unknown_set',
        error = string.format('unknown colorset %s', inspect(set_name)),
      }
  end

  return set, nil
end

---@private
---@return ColorsetsColorscheme|nil
---@return ColorsetsError|nil
function Switcher:_current_colorscheme()
  local ok, colorscheme = pcall(self._get_current_colorscheme)
  if not ok then
    return nil,
      { code = 'switcher_get_current_colorscheme_failed', error = colorscheme }
  end

  if type(colorscheme) ~= 'string' then
    return nil,
      {
        code = 'switcher_invalid_current_colorscheme',
        error = string.format(
          'current colorscheme must be a string, got %s',
          inspect(colorscheme)
        ),
      }
  end

  return colorscheme, nil
end

---@param set_name string
---@return ColorsetsSet|nil
---@return ColorsetsGroup|nil
---@return ColorsetsColorscheme|nil
---@return ColorsetsError|nil
---@private
function Switcher:_current_state(set_name)
  local set, set_err = self:_set_by_name(set_name)
  if set == nil then
    return nil, nil, nil, set_err
  end

  local colorscheme, colorscheme_err = self:_current_colorscheme()
  if colorscheme == nil then
    return nil, nil, nil, colorscheme_err
  end

  local group = set:group_of(colorscheme)

  if group == nil then
    return nil,
      nil,
      nil,
      {
        code = 'switcher_colorscheme_outside_set',
        error = string.format(
          'current colorscheme %s is not in colorset %s',
          inspect(colorscheme),
          inspect(set_name)
        ),
      }
  end

  return set, group, colorscheme, nil
end

---@param set_name string
---@return ColorsetsError|nil err
function Switcher:next(set_name)
  local _, group, current, err = self:_current_state(set_name)
  if group == nil or current == nil then
    return err
  end

  local target = assert(group:next_of(current), 'expected next colorscheme')

  if target.colorscheme ~= current then
    local ok, load_err = pcall(self._load_colorscheme, target.colorscheme)
    if not ok then
      return {
        code = 'switcher_load_colorscheme_failed',
        error = load_err,
      }
    end
  end

  return nil
end

---@param set_name string
---@return ColorsetsError|nil err
function Switcher:prev(set_name)
  local _, group, current, err = self:_current_state(set_name)
  if group == nil or current == nil then
    return err
  end

  local target = assert(group:prev_of(current), 'expected previous colorscheme')

  if target.colorscheme ~= current then
    local ok, load_err = pcall(self._load_colorscheme, target.colorscheme)
    if not ok then
      return {
        code = 'switcher_load_colorscheme_failed',
        error = load_err,
      }
    end
  end

  return nil
end

---@param set_name string
---@param mode ColorsetsMode
---@return ColorsetsError|nil err
function Switcher:set(set_name, mode)
  local set, group, current, err = self:_current_state(set_name)
  if set == nil or group == nil or current == nil then
    return err
  end

  if set.modes:key(mode) == nil then
    return {
      code = 'switcher_unknown_mode',
      error = string.format(
        'unknown mode %s for colorset %s',
        inspect(mode),
        inspect(set_name)
      ),
    }
  end

  local target_colorscheme =
    assert(group:colorscheme(mode), 'expected colorscheme for mode')

  if target_colorscheme ~= current then
    local ok, load_err = pcall(self._load_colorscheme, target_colorscheme)
    if not ok then
      return {
        code = 'switcher_load_colorscheme_failed',
        error = load_err,
      }
    end
  end

  return nil
end

return Switcher
