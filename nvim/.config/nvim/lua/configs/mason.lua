local M = {}

M.ensure_installed = {
  -- LSPs configured in lua/configs/lspconfig.lua
  "ruff",
  "ty",
  "vtsls",
  "tailwindcss-language-server",
  "eslint-lsp",
  "json-lsp",
  "lua-language-server",
  "zls",
  "markdown-oxide",
  "bash-language-server",

  -- Formatters configured in lua/configs/conform.lua
  "stylua",
  "prettier",
}

local function install_missing_packages()
  local registry = require("mason-registry")

  for _, package_name in ipairs(M.ensure_installed) do
    local ok, package = pcall(registry.get_package, package_name)

    if ok and not package:is_installed() and not package:is_installing() then
      package:install()
    end
  end
end

function M.setup(opts)
  require("mason").setup(opts)

  local registry = require("mason-registry")

  registry.refresh(vim.schedule_wrap(install_missing_packages))
end

return M
