# NeatNotes.nvim

A Neovim plugin for efficiently capturing and organizing code snippets and notes directly from your editor.

## Features

- Take notes from visually selected code
- Automatic language detection for syntax highlighting
- Split window or floating window display options
- Reference tracking with file paths and line numbers

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "guglielmobartelloni/neatnotes.nvim",
    config = function()
        require("neatnotes").setup()
    end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'guglielmobartelloni/neatnotes.nvim',
    config = function()
        require('neatnotes').setup()
    end
}
```

## Usage

1. Select text in visual mode
2. Use either:
   - Command: `:TakeNote`
   - Default keybinding: `<leader>tn`

Notes are stored in `~/.local/share/nvim/notes.md`

## Configuration

```lua
require('neatnotes').setup({
    -- Default configuration (coming soon)
})
```

## License

MIT
