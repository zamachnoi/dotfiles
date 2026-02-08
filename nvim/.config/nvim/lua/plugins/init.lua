return {
  {
    "stevearc/conform.nvim",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = function(_, opts)
      opts.renderer = vim.tbl_deep_extend("force", opts.renderer or {}, {
        group_empty = true,
      })

      opts.reload_on_bufenter = true

      opts.filters = vim.tbl_deep_extend("force", opts.filters or {}, {
        git_ignored = false,
      })

      opts.actions = vim.tbl_deep_extend("force", opts.actions or {}, {
        open_file = {
          window_picker = { enable = false },
        },
      })

      opts.filesystem_watchers = vim.tbl_deep_extend("force", opts.filesystem_watchers or {}, {
        enable = false,
      })
      return opts
    end,
  },
}
