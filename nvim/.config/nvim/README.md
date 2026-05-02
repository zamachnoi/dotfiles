**This repo is supposed to be used as config by NvChad users!**

- The main nvchad repo (NvChad/NvChad) is used as a plugin by this repo.
- So you just import its modules , like `require "nvchad.options" , require "nvchad.mappings"`
- So you can delete the .git from this repo ( when you clone it locally ) or fork it :)

# Custom LSP Peek

This config includes a custom LSP type-peek workflow that opens a floating preview of the type under cursor.

- `<C-p>`: Toggle type peek float.
  - First press opens the peek preview.
  - Second press closes the existing preview.
- `<leader>lh`: Toggle auto-hover on `CursorHold`.
  - Default is `off`.
  - Manual peek with `<C-p>` always works.

Implementation details:

- Core logic: `lua/utils/lspeek.lua`
- Auto-hover autocmd: `lua/autocmds.lua`
- Keymaps: `lua/mappings.lua`

# Cheatsheet Float

This config includes a small local `cheatsheet.nvim` plugin that opens a centered floating Q&A window backed by `codex exec`.

- `<leader>at`: Toggle the Cheatsheet window.
- `<leader>aq`: Prompt for a question and append the answer to the transcript.
- `<leader>ar`: Clear the transcript.
- `:Cheatsheet`: Toggle the window, or pass an inline prompt with `:Cheatsheet your question`.
- `:CheatsheetAsk`: Ask a question from the command line or via `vim.ui.input`.
- Inside the window: `a` asks, `c` clears, `q` closes.

The window uses `codex exec` in `read-only` sandbox mode, which keeps the UI simple and better suited to quick, basic questions inside Neovim.

# Credits

1) Lazyvim starter https://github.com/LazyVim/starter as nvchad's starter was inspired by Lazyvim's . It made a lot of things easier!
