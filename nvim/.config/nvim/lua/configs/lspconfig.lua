require("nvchad.configs.lspconfig").defaults()

-- Mason packages currently installed:
-- basedpyright, tsgo, lua-language-server, tailwindcss-language-server, biome, json-lsp, zls, markdown-oxide, rust-analyzer
local zig_exe_path = vim.fn.exepath("zig")

local function get_zls_build_on_save_args(root_dir)
  if not root_dir then
    return nil
  end

  local build_file = root_dir .. "/build.zig"
  local file = io.open(build_file, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  if content and content:find('b%.step%s*%(%s*"check"') then
    return nil
  end

  if content and content:find('b%.step%s*%(%s*"test"') then
    return { "test" }
  end

  return nil
end

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
      "typescript",
      "typescriptreact",
    },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  },
  tailwindcss = {},
  biome = {},
  jsonls = {},
  lua_ls = {
    settings = {
      Lua = {
        codeLens = { enable = true },
        hint = { enable = true, semicolon = "Disable" },
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          checkThirdParty = false,
          library = {
            vim.env.VIMRUNTIME,
            vim.fn.stdpath("config"),
            vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy",
            vim.fn.stdpath("data") .. "/lazy/ui/nvchad_types",
          },
        },
      },
    },
  },
  zls = {
    root_markers = { "build.zig", "zls.json", ".git" },
    before_init = function(_, config)
      local args = get_zls_build_on_save_args(config.root_dir)
      if not args then
        return
      end

      config.settings = config.settings or {}
      config.settings.zls = config.settings.zls or {}
      config.settings.zls.build_on_save_args = args
    end,
    settings = {
      zls = {
        enable_build_on_save = true,
        zig_exe_path = zig_exe_path ~= "" and zig_exe_path or nil,
      },
    },
  },
  markdown_oxide = {},
  rust_analyzer = {},
  bashls = {},
}

for name, opts in pairs(servers) do
  vim.lsp.config(name, opts)
  vim.lsp.enable(name)
end
