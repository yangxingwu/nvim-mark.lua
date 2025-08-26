# nvim-mark.lua

A Neovim plugin written in Lua that provides word highlighting functionality similar to [vim-mark](https://github.com/inkarkat/vim-mark/). The core functionality is to **highlight several words in different colors simultaneously**.

## Features

- **Multiple Word Highlighting**: Mark and highlight multiple words/patterns simultaneously with different colors
- **Literal and Regex Support**: Support both literal string matching and regex patterns
- **Visual Selection**: Mark visually selected text
- **Persistent Across Buffers**: Marks are applied automatically when entering buffers
- **Color Cycling**: Automatically cycles through available colors for new marks
- **vim-mark Compatible Colors**: Uses the same default color palette as the original vim-mark plugin

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yangxingwu/nvim-mark.lua",
  config = function()
    require("mark").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "yangxingwu/nvim-mark.lua",
  config = function()
    require("mark").setup()
  end,
}
```

## Setup

Add the following to your Neovim configuration:

```lua
require("mark").setup()
```

## Usage

### Commands

- `:Mark <pattern>` - Mark a literal word or `/regex/` pattern
- `:Mark add <pattern>` - Add a regex pattern (explicit regex mode)
- `:Mark clear [pattern]` - Clear a specific pattern or all marks if no pattern provided
- `:Mark list` - List all active marks

### Key Mappings

The plugin provides `<Plug>` mappings that you can map to your preferred keys. The main feature is **toggle functionality** - the same key both marks and unmarks text, similar to the original vim-mark plugin.

#### Recommended Key Mappings

```lua
-- Toggle mark for word under cursor or visual selection (same key for mark/unmark)
vim.keymap.set('n', '<Leader>m', '<Plug>MarkWord', { desc = 'Toggle mark for word under cursor' })
vim.keymap.set('v', '<Leader>m', '<Plug>MarkVisual', { desc = 'Toggle mark for visual selection' })

-- Additional useful mappings:
vim.keymap.set('n', '<Leader>mc', ':Mark clear<CR>', { desc = 'Clear all marks' })
vim.keymap.set('n', '<Leader>ml', ':Mark list<CR>', { desc = 'List all marks' })
vim.keymap.set('n', '<Leader>mn', ':Mark add ', { desc = 'Add new mark pattern' })
```

#### Vimscript Alternative

```vim
" Toggle mark for word under cursor or visual selection (same key for mark/unmark)
nmap <Leader>m <Plug>MarkWord
vmap <Leader>m <Plug>MarkVisual

" Additional useful mappings:
nmap <Leader>mc :Mark clear<CR>
nmap <Leader>ml :Mark list<CR>
nmap <Leader>mn :Mark add
```

#### Key Features

- **`<Leader>m`**: Toggle mark/unmark for word under cursor or visual selection
- **`<Leader>mc`**: Clear all marks
- **`<Leader>ml`**: List all active marks
- **`<Leader>mn`**: Add new mark pattern (interactive)

### Examples

```vim
" Mark literal words
:Mark hello
:Mark world

" Mark regex patterns
:Mark /\d\+/
:Mark add \w+@\w+\.\w+

" Clear specific mark
:Mark clear hello

" Clear all marks
:Mark clear

" List active marks
:Mark list
```

## Configuration

### Custom Colors

You can customize the highlight colors by setting `vim.g.mark_plugin_colors` before calling `setup()`:

```lua
vim.g.mark_plugin_colors = {
  "#FF0000", -- Red
  "#00FF00", -- Green
  "#0000FF", -- Blue
  "#FFFF00", -- Yellow
  "#FF00FF", -- Magenta
  "#00FFFF", -- Cyan
}

require("mark").setup()
```

### Default Colors

By default, the plugin uses the same color palette as vim-mark's 'original' theme:

1. `#8CCBEA` - Cyan background
2. `#A4E57E` - Green background  
3. `#FFDB72` - Yellow background
4. `#FF7272` - Red background
5. `#FFB3FF` - Magenta background
6. `#9999FF` - Blue background

## How It Works

The plugin uses Neovim's extmarks API to create persistent highlights that:

- Survive buffer reloads and window changes
- Are automatically applied to new buffers
- Support both literal string and regex pattern matching
- Use vim.regex for proper Vim-compatible regex support

## Comparison with vim-mark

This plugin aims to provide the core functionality of vim-mark with a modern Lua implementation:

- ✅ Multiple simultaneous word highlighting
- ✅ Color cycling through predefined palette
- ✅ Literal and regex pattern support
- ✅ Visual selection marking
- ✅ Compatible default colors
- ✅ Cross-buffer persistence

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
