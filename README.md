# colorsets.nvim

Stateless colorscheme switcher for Neovim

- Group related colorschemes into named sets
- Keep multiple groups in one set, preserve the current group while switching modes
- Switch from Lua or through the built-in `:Colorset` command with completion

## Install

<details>
<summary>With <code>vim.pack</code></summary>

```lua
vim.pack.add({ 'https://github.com/Picalines/colorsets.nvim' })
```
</details>

<details>
<summary>With <code>lazy.nvim</code></summary>

```lua
{ 'Picalines/colorsets.nvim' }
```
</details>

## Quick Example

```lua
require('colorsets').setup {
  sets = {
    daytime = {
      modes = { 'light', 'dark' },
      colorschemes = {
        { light = 'dayfox', dark = 'nightfox' },
        { light = 'perpetua-light', dark = 'perpetua-dark' },
      },
    },
    contrast = {
      modes = { 'low', 'high' },
      colorschemes = {
        { low = 'terafox', high = 'carbonfox' },
      },
    },
  },
}

-- Switch colorscheme with a user command:
-- `:Colorset daytime next` switches from `dayfox` to `nightfox`
-- `:Colorset daytime prev` switches from `perpetua-dark` to `perpetua-light`
-- `:Colorset contrast set high` switches from `terafox` to `carbonfox`

-- Switch with a keymap:
vim.keymap.set('n', '<Leader>tt', '<Cmd>Colorset daytime next<CR>')
vim.keymap.set('n', '<Leader>tl', '<Cmd>Colorset daytime set light<CR>')
vim.keymap.set('n', '<Leader>td', '<Cmd>Colorset daytime set dark<CR>')

-- Switch through lua functions:
require('colorsets').next 'daytime'
require('colorsets').set('contrast', 'high')
```

## Config

```lua
require('colorsets').setup {
  -- Rename the :Colorset command or disable it:
  command = { name = 'Colorset' },
  -- command = false

  -- Change how a colorscheme is detected and loaded
  current_colorscheme = function()
    return vim.g.colors_name
  end,
  load_colorscheme = function(colorscheme)
    vim.cmd.colorscheme(colorscheme)
  end,

  -- Define sets of colorschemes
  sets = {
    set_name = {
      -- Defines names and order of modes
      modes = { 'mode-1', 'mode-2', 'mode-N' },
      colorschemes = {
        {
          -- A colorscheme must be unique inside one set
          ['mode-1'] = 'scheme-1',
          ['mode-2'] = 'scheme-2',
          ['mode-N'] = 'scheme-N'
        },
      },
    },
  },
}
```

## Using with auto-dark-mode.nvim

`colorsets.nvim` pairs well with [auto-dark-mode.nvim](https://github.com/f-person/auto-dark-mode.nvim) if you want to switch a set from OS light/dark changes without relying on `'background'`

```lua
local colorsets = require 'colorsets'

require('auto-dark-mode').setup {
  set_dark_mode = function()
    colorsets.set('daytime', 'dark')
  end,
  set_light_mode = function()
    colorsets.set('daytime', 'light')
  end,
}
```

## Shout-outs

- https://github.com/f-person/auto-dark-mode.nvim
- https://github.com/edeneast/nightfox.nvim
- https://github.com/perpetuatheme/nvim
- https://github.com/ellisonleao/gruvbox.nvim

## Why?

Different Neovim colorscheme handle `'background'` differently, and I had cases where simple option toggle wasn't enough. With this plugin it's possible to make all sorts of colorscheme grouping like light/dark and hight/low contrast
