return {
  {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<CR>", mode = { "n", "t", "v" }, silent = true, desc = "tmux navigate left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<CR>", mode = { "n", "t", "v" }, silent = true, desc = "tmux navigate down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<CR>", mode = { "n", "t", "v" }, silent = true, desc = "tmux navigate up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<CR>", mode = { "n", "t", "v" }, silent = true, desc = "tmux navigate right" },
    },
  },
}
