local inspect = vim.inspect

local M = {}

---@param err unknown
---@return string
local function error_message(err)
  if type(err) == 'table' and err.error ~= nil then
    return tostring(err.error)
  end
  return tostring(err)
end

---@param err unknown
---@return boolean
local function is_command_error(err)
  return type(err) == 'table' and err.code == 'user_command_error'
end

---@param message string
---@return ColorsetsError
local function new_command_error(message)
  return { error = message, code = 'user_command_error' }
end

---@param err ColorsetsError|nil
local function raise_switcher_error(err)
  if err ~= nil then
    error(new_command_error(error_message(err)), 0)
  end
end

---@param message string
local function command_error(message)
  error(new_command_error(message), 0)
end

---@param items string[]
---@param arg_lead string
---@return string[]
local function complete_matches(items, arg_lead)
  local matches = {}
  for _, item in ipairs(items) do
    if vim.startswith(item, arg_lead) then
      table.insert(matches, item)
    end
  end
  return matches
end

---@class ColorsetsUserSubcommand
---@field args integer
---@field complete? fun(switcher: ColorsetsSwitcher, set_name: string, arg_lead: string, args: string[]): string[]
---@field run fun(switcher: ColorsetsSwitcher, set_name: string, args: string[])

---@type table<string, ColorsetsUserSubcommand>
local subcommands = {
  next = {
    args = 0,
    run = function(switcher, set_name)
      raise_switcher_error(switcher:next(set_name))
    end,
  },
  prev = {
    args = 0,
    run = function(switcher, set_name)
      raise_switcher_error(switcher:prev(set_name))
    end,
  },
  set = {
    args = 1,
    complete = function(switcher, set_name, arg_lead)
      local modes = switcher:modes_of(set_name)
      if modes == nil then
        return {}
      end
      return complete_matches(modes, arg_lead)
    end,
    run = function(switcher, set_name, args)
      raise_switcher_error(switcher:set(set_name, args[1]))
    end,
  },
}

---@return string[]
local function action_names()
  local names = {}
  for action in pairs(subcommands) do
    table.insert(names, action)
  end
  table.sort(names)
  return names
end

---@param switcher ColorsetsSwitcher
---@param arg_lead string
---@param cmd_line string
---@return string[]
local function complete(switcher, arg_lead, cmd_line)
  local tokens = vim.split(vim.trim(cmd_line), '%s+', { trimempty = true })
  local args = {}

  for index = 2, #tokens do
    table.insert(args, tokens[index])
  end

  local arg_index = #args
  if cmd_line:match '%s$' then
    arg_index = arg_index + 1
  end

  if arg_index <= 1 then
    return complete_matches(switcher:set_names(), arg_lead)
  end

  if arg_index == 2 then
    return complete_matches(action_names(), arg_lead)
  end

  local subcommand = subcommands[args[2]]
  if subcommand == nil or subcommand.complete == nil then
    return {}
  end

  return subcommand.complete(
    switcher,
    args[1],
    arg_lead,
    vim.list_slice(args, 3)
  )
end

---@param switcher ColorsetsSwitcher
---@param fargs string[]
local function run(switcher, fargs)
  local set_name = fargs[1]
  local action = fargs[2]

  if set_name == nil then
    command_error 'expected colorset name'
  end

  if action == nil then
    command_error 'expected colorset action'
  end

  local subcommand = subcommands[action]
  if subcommand == nil then
    command_error(string.format('unknown colorset action %s', inspect(action)))
  end

  local actual_subcommand = assert(subcommand, 'expected colorset subcommand')
  local args = vim.list_slice(fargs, 3)
  if #args < actual_subcommand.args then
    command_error(
      string.format(
        'not enough arguments for colorset action %s',
        inspect(action)
      )
    )
  end

  if #args > actual_subcommand.args then
    command_error(
      string.format(
        'too many arguments for colorset action %s',
        inspect(action)
      )
    )
  end

  actual_subcommand.run(switcher, set_name, args)
end

---@param switcher ColorsetsSwitcher
---@param command_config ColorsetsConfigCommand|false
function M.create(switcher, command_config)
  if command_config == false then
    return
  end

  vim.api.nvim_create_user_command(command_config.name, function(opts)
    local ok, err = pcall(run, switcher, opts.fargs)
    if ok then
      return
    end

    if not is_command_error(err) then
      error(err)
    end

    if not opts.smods.emsg_silent then
      vim.api.nvim_echo({ { error_message(err) } }, true, { err = true })
    end
  end, {
    nargs = '*',
    complete = function(arg_lead, cmd_line)
      return complete(switcher, arg_lead, cmd_line)
    end,
  })
end

return M
