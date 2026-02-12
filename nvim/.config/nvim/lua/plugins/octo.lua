return {
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      -- Allow bare :Octo to open the builtin command picker.
      enable_builtin = true,
      picker = "telescope",
    },
    keys = {
      { "<leader>go", "<cmd>Octo<CR>", desc = "octo" },
      { "<leader>gi", "<cmd>Octo issue list<CR>", desc = "github issues" },
      { "<leader>gP", "<cmd>Octo pr list<CR>", desc = "github prs" },
    },
  },
}
