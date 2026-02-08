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

  -- nvim-tree filewatcher
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      filesystem_watchers = {
        enable = true,
        debounce_delay = 50,
      },
    },
  },
}
