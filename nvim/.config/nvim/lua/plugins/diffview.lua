return {
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    init = function()
      vim.api.nvim_create_user_command("DiffviewMaster", function()
        vim.cmd("DiffviewOpen master...HEAD")
      end, { desc = "Open diffview against master" })
    end,
    opts = {
      enhanced_diff_hl = true,
      use_icons = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
      file_panel = {
        win_config = {
          position = "left",
          width = 35,
        },
      },
    },
    keys = {
      { "<leader>gvo", "<cmd>DiffviewOpen<CR>", desc = "git diffview open" },
      { "<leader>gvm", "<cmd>DiffviewMaster<CR>", desc = "git diffview master...HEAD" },
      { "<leader>gvc", "<cmd>DiffviewClose<CR>", desc = "git diffview close" },
      { "<leader>gvh", "<cmd>DiffviewFileHistory %<CR>", desc = "git file history" },
      { "<leader>gvH", "<cmd>DiffviewFileHistory<CR>", desc = "git repo history" },
    },
  },
}
