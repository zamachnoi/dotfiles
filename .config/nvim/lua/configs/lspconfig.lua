require("nvchad.configs.lspconfig").defaults()

vim.lsp.config("ty", {
  cmd = { "ty", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ty.toml", ".git" },
})

vim.lsp.config("tsgo", {
  cmd = { "tsgo", "--lsp", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})

-- Mason packages currently installed:
-- ty, tsgo, lua-language-server, tailwindcss-language-server, biome, json-lsp
-- LSP names below are the corresponding lspconfig server IDs.
local servers = { "ty", "tsgo", "lua_ls", "tailwindcss", "biome", "jsonls" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
