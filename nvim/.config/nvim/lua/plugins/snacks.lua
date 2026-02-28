local startup_cwd = (vim.uv or vim.loop).cwd() or vim.fn.getcwd()
local snacks_keys = require("utils.snacks_keys")

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    keys = snacks_keys.keys,
    opts = {
      bigfile = { enabled = true },
      input = { enabled = true },
      lazygit = { enabled = true },
      notifier = { enabled = true },
      picker = {
        enabled = true,
        cwd = startup_cwd,
        sources = {
          recent = {
            filter = { cwd = true },
          },
          smart = {
            filter = { cwd = true },
          },
        },
      },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = false },
      words = { enabled = true },
      image = { enabled = true },
    },
  },
}
