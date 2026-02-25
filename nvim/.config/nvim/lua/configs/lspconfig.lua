require("nvchad.configs.lspconfig").defaults()

local workspace = require("configs.python_workspace")

-- Mason packages currently installed:
-- ruff, basedpyright, tsgo, lua-language-server, tailwindcss-language-server, biome, json-lsp, zls, markdown-oxide
local zig_exe_path = vim.fn.exepath("zig")

local function python_root_dir(bufnr, on_dir)
  local root = workspace.find_python_root(vim.api.nvim_buf_get_name(bufnr))
  if root then
    on_dir(root)
  end
end

local function llm_root_dir(bufnr, on_dir)
  local root = workspace.find_llm_root(vim.api.nvim_buf_get_name(bufnr))
  if root then
    on_dir(root)
  end
end

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
  ruff = {
    filetypes = { "python" },
    root_dir = llm_root_dir,
    before_init = function(_, config)
      config.cmd = {
        workspace.resolve_llm_tool(config.root_dir, "ruff"),
        "server",
      }
    end,
  },
  basedpyright = {
    filetypes = { "python" },
    root_dir = python_root_dir,
    -- Keep diagnostics sourced from ruff+ty; use basedpyright for nav/intel.
    handlers = {
      ["textDocument/publishDiagnostics"] = function() end,
    },
    settings = {
      python = {
        analysis = {
          typeCheckingMode = "off",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
        },
      },
      basedpyright = {
        disableOrganizeImports = true,
      },
    },
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
  bashls = {},
}

for name, opts in pairs(servers) do
  vim.lsp.config(name, opts)
  vim.lsp.enable(name)
end
