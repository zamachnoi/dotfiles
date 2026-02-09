require("nvchad.configs.lspconfig").defaults()

vim.lsp.config("basedpyright", {
  filetypes = { "python" },
  root_markers = { "pyproject.toml", ".git" },
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
-- basedpyright, tsgo, lua-language-server, tailwindcss-language-server, biome, json-lsp, zls, markdown-oxide
-- LSP names below are the corresponding lspconfig server IDs.
local servers = { "basedpyright", "tsgo", "lua_ls", "tailwindcss", "biome", "jsonls", "zls", "markdown_oxide", "bashls" }
vim.lsp.enable(servers)
