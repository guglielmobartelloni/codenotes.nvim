# CodeNotes.nvim

A Neovim plugin for efficiently capturing and organizing code snippets and notes directly from your editor.

## What problem it solves?

When reviewing code in a project, it's often helpful to take notes with comments and explanations about the code’s functionality. 
However, manually copying code into a separate file for note-taking can be tedious, and it’s easy to lose context and references in the process.

Introducing codenotes.nvim – a simple note-taking plugin that automatically creates a dedicated note file for your project. It inserts the selected code snippet with references to the file and line numbers in a clean, easy-to-read markdown format.

![Preview](https://i.imgur.com/eMkbQQj.gif)


## Features

- Take notes from visually selected code
- Floating window support
- Automatic language detection for syntax highlighting
- Reference tracking with file paths and line numbers

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "guglielmobartelloni/codenotes.nvim",
    config = function()
        require("codenotes").setup()
    end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'guglielmobartelloni/codenotes.nvim',
    config = function()
        require('codenotes').setup()
    end
}
```

## Usage

1. Select text in visual mode
2. Use either:
   - Command: `:TakeNote`
   - Default keybinding: `<leader>tn`

Notes are stored in `~/.local/share/nvim/`

## Configuration

```lua
require('codenotes').setup({
    notes_dir = "/your/custom/path/",
	use_floating_window = false,
})
```

## License

MIT
