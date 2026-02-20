local workspace = require("configs.python_workspace")

local function orb_python(ctx)
  return workspace.orb_python(ctx.filename) or "python3"
end

local function llm_tool(ctx, exe)
  return workspace.resolve_llm_tool(ctx.filename, exe)
end

local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    python = function(bufnr)
      local filename = vim.api.nvim_buf_get_name(bufnr)

      if workspace.is_orb_file(filename) then
        return { "isort_orb", "black_orb" }
      end

      if workspace.is_llm_file(filename) then
        return { "ruff_format_llm" }
      end

      return {}
    end,
    javascript = { "biome" },
    javascriptreact = { "biome" },
    typescript = { "biome" },
    typescriptreact = { "biome" },
    json = { "biome" },
    jsonc = { "biome" },
  },

  formatters = {
    isort_orb = {
      command = function(_, ctx)
        return orb_python(ctx)
      end,
      args = function(_, ctx)
        local root = workspace.find_orb_root(ctx.filename)
        if not root then
          return { "-m", "isort", "$FILENAME" }
        end

        return {
          "-m",
          "isort",
          "--settings-path",
          root .. "/pyproject.toml",
          "$FILENAME",
        }
      end,
      stdin = false,
      cwd = function(_, ctx)
        return workspace.find_orb_root(ctx.filename)
      end,
    },

    black_orb = {
      command = function(_, ctx)
        return orb_python(ctx)
      end,
      args = function(_, ctx)
        local root = workspace.find_orb_root(ctx.filename)
        if not root then
          return { "-m", "black", "$FILENAME" }
        end

        return {
          "-m",
          "black",
          "--config",
          root .. "/pyproject.toml",
          "$FILENAME",
        }
      end,
      stdin = false,
      cwd = function(_, ctx)
        return workspace.find_orb_root(ctx.filename)
      end,
    },

    ruff_format_llm = {
      command = function(_, ctx)
        return llm_tool(ctx, "ruff")
      end,
      args = {
        "format",
        "$FILENAME",
      },
      stdin = false,
      cwd = function(_, ctx)
        return workspace.find_llm_root(ctx.filename)
      end,
    },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
