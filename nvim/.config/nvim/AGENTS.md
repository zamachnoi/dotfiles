# AGENTS.md

## Scope
- Applies to everything under `.config/nvim`.

## Repo Intent
- This is an NvChad-based user config.
- Keep overrides minimal, explicit, and easy to review.

## NvChad Docs
- Mappings: https://nvchad.com/docs/config/mappings
- Plugins: https://nvchad.com/docs/config/plugins
- Base config reference (`nvconfig.lua` structure): https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

## Config Conventions
- Put global/editor mappings in `lua/mappings.lua`.
- Put plugin-specific mappings in plugin specs under `lua/plugins/` using `keys = { ... }`.
- Never overwrite existing mappings; check both this repo and NvChad defaults before adding/changing keys.
- NvChad default mappings file: `/Users/nick/.local/share/nvim/lazy/NvChad/lua/nvchad/mappings.lua`.
- Prefer `opts = { ... }` or `opts = function(_, opts) ... end` for plugin setup.
- Avoid `config = function()` unless there is no clean `opts`/`keys` path.
- Plugin files under `lua/plugins/*.lua` are auto-discovered via `import = "plugins"` in `init.lua`; no manual registration needed for new spec files.

## LSP Peek
- Custom module: `lua/utils/lspeek.lua`.
- `<C-p>` toggles type peek float open/closed.
- `<leader>lh` toggles auto-hover on `CursorHold` (default: off).

## Editing Rules
- Use ASCII unless the file already requires Unicode.
- Keep comments short and only for non-obvious logic.
- Don’t revert unrelated user changes.

## Validation
- Lua format check:
  - `~/.local/share/nvim/mason/bin/stylua --check lua/**/*.lua`
- Headless startup check:
  - `XDG_CACHE_HOME=/tmp XDG_STATE_HOME=/tmp nvim --headless '+qa'`
