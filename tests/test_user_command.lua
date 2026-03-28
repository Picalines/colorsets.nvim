local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local Set = require 'colorsets.core.set'
local Switcher = require 'colorsets.core.switcher'
local user_command = require 'colorsets.user_command'

---@param fn fun()
local function with_restored_vim_api(fn)
  local original_api = vim.api

  local ok, err = pcall(fn)

  vim.api = original_api

  if not ok then
    error(err)
  end
end

---@param create_user_command fun(name: string, callback: fun(opts: table), opts: table)
local function mock_nvim_create_user_command(create_user_command)
  local original_api = vim.api

  vim.api = setmetatable({
    nvim_create_user_command = create_user_command,
  }, { __index = original_api })
end

---@param echo fun(chunks: string[][], history: boolean, opts: table)
local function mock_nvim_echo(echo)
  local original_api = vim.api

  vim.api = setmetatable({
    nvim_echo = echo,
  }, { __index = original_api })
end

---@param colorscheme? ColorsetsColorscheme
---@return ColorsetsSwitcher
---@return { current: ColorsetsColorscheme, loaded: ColorsetsColorscheme[] }
local function new_switcher(colorscheme)
  local state = {
    current = colorscheme or 'dayfox',
    loaded = {},
  }

  local switcher = Switcher.new {
    sets = {
      contrast = Set.new(
        { 'low', 'high' },
        { { low = 'terafox', high = 'carbonfox' } }
      ),
      daytime = Set.new(
        { 'light', 'dark' },
        { { light = 'dayfox', dark = 'nightfox' } }
      ),
    },
    current_colorscheme = function()
      return state.current
    end,
    load_colorscheme = function(target)
      table.insert(state.loaded, target)
      state.current = target
    end,
  }

  return switcher, state
end

local T = new_set()

T['command'] = new_set()

T['command']['create'] = new_set()

T['command']['create']['registers user command with completion'] = function()
  with_restored_vim_api(function()
    local created_name
    local created_callback
    local created_opts
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(name, callback, opts)
      created_name = name
      created_callback = callback
      created_opts = opts
    end)

    user_command.create(switcher, { name = 'Colorset' })

    eq(created_name, 'Colorset')
    eq(type(created_callback), 'function')
    eq(created_opts.nargs, '*')
    eq(type(created_opts.complete), 'function')
  end)
end

T['command']['create']['does nothing when disabled'] = function()
  with_restored_vim_api(function()
    local created = false
    local switcher = new_switcher()

    mock_nvim_create_user_command(function()
      created = true
    end)

    user_command.create(switcher, false)

    eq(created, false)
  end)
end

T['command']['create']['dispatches next action to switcher'] = function()
  with_restored_vim_api(function()
    local created_callback
    local switcher, state = new_switcher 'dayfox'

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    user_command.create(switcher, { name = 'Colorset' })
    created_callback { fargs = { 'daytime', 'next' } }

    eq(state.loaded, { 'nightfox' })
  end)
end

T['command']['create']['dispatches prev action to switcher'] = function()
  with_restored_vim_api(function()
    local created_callback
    local switcher, state = new_switcher 'carbonfox'

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    user_command.create(switcher, { name = 'Colorset' })
    created_callback { fargs = { 'contrast', 'prev' } }

    eq(state.loaded, { 'terafox' })
  end)
end

T['command']['create']['dispatches set action to switcher'] = function()
  with_restored_vim_api(function()
    local created_callback
    local switcher, state = new_switcher 'dayfox'

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    user_command.create(switcher, { name = 'Colorset' })
    created_callback { fargs = { 'daytime', 'set', 'dark' } }

    eq(state.loaded, { 'nightfox' })
  end)
end

T['command']['create']['raises switcher errors from callbacks'] = function()
  with_restored_vim_api(function()
    local created_callback
    local echoed_chunks
    local echoed_history
    local echoed_opts
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    mock_nvim_echo(function(chunks, history, opts)
      echoed_chunks = chunks
      echoed_history = history
      echoed_opts = opts
    end)

    user_command.create(switcher, { name = 'Colorset' })

    created_callback { fargs = { 'missing', 'next' }, smods = {} }

    eq(echoed_chunks, { { 'unknown colorset "missing"' } })
    eq(echoed_history, true)
    eq(echoed_opts, { err = true })
  end)
end

T['command']['create']['shows errors under silent modifier'] = function()
  with_restored_vim_api(function()
    local created_callback
    local echoed_chunks
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    mock_nvim_echo(function(chunks)
      echoed_chunks = chunks
    end)

    user_command.create(switcher, { name = 'Colorset' })

    created_callback {
      fargs = { 'daytime', 'rotate' },
      smods = { silent = true },
    }

    eq(echoed_chunks, { { 'unknown colorset action "rotate"' } })
  end)
end

T['command']['create']['suppresses errors under silent bang modifier'] = function()
  with_restored_vim_api(function()
    local created_callback
    local echoed = false
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    mock_nvim_echo(function()
      echoed = true
    end)

    user_command.create(switcher, { name = 'Colorset' })

    created_callback {
      fargs = { 'daytime', 'rotate' },
      smods = { emsg_silent = true },
    }

    eq(echoed, false)
  end)
end

T['command']['create']['raises error on unknown action'] = function()
  with_restored_vim_api(function()
    local created_callback
    local echoed_chunks
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    mock_nvim_echo(function(chunks)
      echoed_chunks = chunks
    end)

    user_command.create(switcher, { name = 'Colorset' })

    created_callback { fargs = { 'daytime', 'rotate' }, smods = {} }

    eq(echoed_chunks, { { 'unknown colorset action "rotate"' } })
  end)
end

T['command']['create']['raises error when set is missing'] = function()
  with_restored_vim_api(function()
    local created_callback
    local echoed_chunks
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    mock_nvim_echo(function(chunks)
      echoed_chunks = chunks
    end)

    user_command.create(switcher, { name = 'Colorset' })

    created_callback { fargs = {}, smods = {} }

    eq(echoed_chunks, { { 'expected colorset name' } })
  end)
end

T['command']['create']['raises error when action is missing'] = function()
  with_restored_vim_api(function()
    local created_callback
    local echoed_chunks
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    mock_nvim_echo(function(chunks)
      echoed_chunks = chunks
    end)

    user_command.create(switcher, { name = 'Colorset' })

    created_callback { fargs = { 'daytime' }, smods = {} }

    eq(echoed_chunks, { { 'expected colorset action' } })
  end)
end

T['command']['create']['raises error when set mode is missing'] = function()
  with_restored_vim_api(function()
    local created_callback
    local echoed_chunks
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    mock_nvim_echo(function(chunks)
      echoed_chunks = chunks
    end)

    user_command.create(switcher, { name = 'Colorset' })

    created_callback { fargs = { 'daytime', 'set' }, smods = {} }

    eq(echoed_chunks, { { 'not enough arguments for colorset action "set"' } })
  end)
end

T['command']['create']['raises error on unexpected mode for next'] = function()
  with_restored_vim_api(function()
    local created_callback
    local echoed_chunks
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    mock_nvim_echo(function(chunks)
      echoed_chunks = chunks
    end)

    user_command.create(switcher, { name = 'Colorset' })

    created_callback { fargs = { 'daytime', 'next', 'dark' }, smods = {} }

    eq(echoed_chunks, { { 'too many arguments for colorset action "next"' } })
  end)
end

T['command']['create']['raises error on extra mode for set'] = function()
  with_restored_vim_api(function()
    local created_callback
    local echoed_chunks
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, callback)
      created_callback = callback
    end)

    mock_nvim_echo(function(chunks)
      echoed_chunks = chunks
    end)

    user_command.create(switcher, { name = 'Colorset' })

    created_callback {
      fargs = { 'daytime', 'set', 'dark', 'extra' },
      smods = {},
    }

    eq(echoed_chunks, { { 'too many arguments for colorset action "set"' } })
  end)
end

T['command']['create']['completes actions'] = function()
  with_restored_vim_api(function()
    local created_opts
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, _, opts)
      created_opts = opts
    end)

    user_command.create(switcher, { name = 'Colorset' })

    eq(created_opts.complete('n', 'Colorset daytime n'), { 'next' })
  end)
end

T['command']['create']['completes set names first'] = function()
  with_restored_vim_api(function()
    local created_opts
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, _, opts)
      created_opts = opts
    end)

    user_command.create(switcher, { name = 'Colorset' })

    eq(created_opts.complete('d', 'Colorset d'), { 'daytime' })
  end)
end

T['command']['create']['completes modes for set action'] = function()
  with_restored_vim_api(function()
    local created_opts
    local switcher = new_switcher()

    mock_nvim_create_user_command(function(_, _, opts)
      created_opts = opts
    end)

    user_command.create(switcher, { name = 'Colorset' })

    eq(created_opts.complete('d', 'Colorset daytime set d'), { 'dark' })
  end)
end

return T
