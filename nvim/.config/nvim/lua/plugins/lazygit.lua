return {
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>gl", "<cmd>LazyGit<CR>", desc = "lazygit" },
      { "<leader>gL", "<cmd>LazyGitCurrentFile<CR>", desc = "lazygit current file" },
    },
  },
}
