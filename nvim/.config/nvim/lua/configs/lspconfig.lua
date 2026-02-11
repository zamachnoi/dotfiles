require("nvchad.configs.lspconfig").defaults()

-- Mason packages currently installed:
-- basedpyright, tsgo, lua-language-server, tailwindcss-language-server, biome, json-lsp, zls, markdown-oxide
local servers = {
  basedpyright = {
    filetypes = { "python" },
    root_markers = { "pyproject.toml", ".git" },
  },
  tsgo = {
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
  },
  lua_ls = {},
  tailwindcss = {},
  biome = {},
  jsonls = {},
  zls = {},
  markdown_oxide = {},
  bashls = {},
}

for name, opts in pairs(servers) do
  vim.lsp.config(name, opts)
  vim.lsp.enable(name)
end
