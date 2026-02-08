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
      opts.reload_on_bufenter = true
      opts.filters = vim.tbl_deep_extend("force", opts.filters or {}, {
        git_ignored = false,
      })
      opts.git = vim.tbl_deep_extend("force", opts.git or {}, {
        enable = true,
        show_on_dirs = true,
        show_on_open_dirs = true,
      })
      opts.filesystem_watchers = vim.tbl_deep_extend("force", opts.filesystem_watchers or {}, {
        enable = false,
      })
      return opts
    end,
  },
}
