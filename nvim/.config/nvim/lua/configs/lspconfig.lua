require("nvchad.configs.lspconfig").defaults()

local zig_exe_path = vim.fn.exepath("zig")
local path_sep = package.config:sub(1, 1)
local env_path_sep = vim.fn.has("win32") == 1 and ";" or ":"

local function disable_lsp_formatting(client)
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false
end

local function is_dir(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.type == "directory"
end

local function parent_dir(path)
  local parent = vim.fs.dirname(path)
  if not parent or parent == "" or parent == path then
    return nil
  end

  return parent
end

local function prepend_env_path(path, current)
  if not current or current == "" then
    return path
  end

  local parts = vim.split(current, env_path_sep, { plain = true, trimempty = true })
  if vim.tbl_contains(parts, path) then
    return current
  end

  return path .. env_path_sep .. current
end

local function find_python_venv_root(start_dir)
  local dir = start_dir
  while dir do
    if is_dir(dir .. path_sep .. ".venv") then
      return dir
    end

    dir = parent_dir(dir)
  end

  return nil
end

local function python_cmd_env(root_dir, current_env)
  local venv_root = find_python_venv_root(root_dir)
  if not venv_root then
    return current_env, nil
  end

  local venv_dir = venv_root .. path_sep .. ".venv"
  local bin_dir = venv_dir .. path_sep .. (vim.fn.has("win32") == 1 and "Scripts" or "bin")
  local env = vim.tbl_extend("force", vim.fn.environ(), current_env or {})
  env.VIRTUAL_ENV = venv_dir
  env.PATH = prepend_env_path(bin_dir, env.PATH)
  return env, venv_root
end

local function python_server_cmd(exe, args)
  return function(dispatchers, config)
    local env, venv_root = python_cmd_env(config.root_dir, config.cmd_env)
    local cmd = vim.list_extend({ exe }, args or {})

    return vim.lsp.rpc.start(cmd, dispatchers, {
      cwd = venv_root or config.cmd_cwd,
      env = env,
      detached = config.detached,
    })
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
    cmd = python_server_cmd("ruff", { "server" }),
    root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", "uv.lock", "requirements.txt", ".venv", ".git" },
  },
  ty = {
    cmd = python_server_cmd("ty", { "server" }),
    root_markers = {
      "ty.toml",
      "pyproject.toml",
      "uv.lock",
      "setup.py",
      "setup.cfg",
      "requirements.txt",
      ".venv",
      ".git",
    },
  },
  vtsls = {
    filetypes = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
    },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
    on_attach = disable_lsp_formatting,
    settings = {
      vtsls = {
        autoUseWorkspaceTsdk = true,
      },
      typescript = {
        updateImportsOnFileMove = { enabled = "always" },
      },
      javascript = {
        updateImportsOnFileMove = { enabled = "always" },
      },
    },
  },
  tailwindcss = {
    filetypes = {
      "astro",
      "css",
      "html",
      "javascript",
      "javascriptreact",
      "scss",
      "typescript",
      "typescriptreact",
      "vue",
    },
    root_markers = {
      "tailwind.config.js",
      "tailwind.config.cjs",
      "tailwind.config.mjs",
      "tailwind.config.ts",
      "tailwind.config.cts",
      "tailwind.config.mts",
      "postcss.config.js",
      "postcss.config.cjs",
      "postcss.config.mjs",
      "postcss.config.ts",
      "postcss.config.cts",
      "postcss.config.mts",
      "package.json",
      ".git",
    },
    on_attach = disable_lsp_formatting,
  },
  eslint = {
    filetypes = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
    },
    root_markers = {
      "eslint.config.js",
      "eslint.config.cjs",
      "eslint.config.mjs",
      "eslint.config.ts",
      "eslint.config.cts",
      "eslint.config.mts",
      ".eslintrc",
      ".eslintrc.js",
      ".eslintrc.cjs",
      ".eslintrc.json",
      ".eslintrc.yaml",
      ".eslintrc.yml",
      "package.json",
      ".git",
    },
    settings = {
      workingDirectory = { mode = "auto" },
    },
    on_attach = disable_lsp_formatting,
  },
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
