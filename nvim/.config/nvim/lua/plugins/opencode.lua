return {
  {
    "nickjvandyke/opencode.nvim",
    dependencies = {
      { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
    },
    init = function()
      vim.g.opencode_opts = vim.g.opencode_opts or {}
    end,
    keys = {
      {
        "<leader>ot",
        function()
          require("opencode").toggle()
        end,
        mode = "n",
        desc = "opencode toggle",
      },
      {
        "<leader>oa",
        function()
          require("opencode").select()
        end,
        mode = { "n", "x" },
        desc = "opencode actions",
      },
      {
        "<leader>or",
        function()
          return require("opencode").operator("@this ")
        end,
        expr = true,
        mode = { "n", "x" },
        desc = "opencode add range",
      },
      {
        "<leader>ol",
        function()
          return require("opencode").operator("@this ") .. "_"
        end,
        expr = true,
        mode = "n",
        desc = "opencode add line",
      },
      {
        "[o",
        function()
          require("opencode").command("session.half.page.up")
        end,
        mode = "n",
        desc = "opencode scroll up",
      },
      {
        "]o",
        function()
          require("opencode").command("session.half.page.down")
        end,
        mode = "n",
        desc = "opencode scroll down",
      },
    },
  },
}
