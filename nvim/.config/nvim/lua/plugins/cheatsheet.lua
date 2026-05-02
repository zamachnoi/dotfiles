return {
  {
    "git@polaris-git.cisco.com:nzamachn/cheatsheet.nvim.git",
    cmd = { "Cheatsheet", "CheatsheetAsk", "CheatsheetClear" },
    keys = {
      {
        "<leader>at",
        function()
          require("cheatsheet").toggle()
        end,
        mode = "n",
        desc = "cheatsheet toggle",
      },
      {
        "<leader>aq",
        function()
          require("cheatsheet").ask()
        end,
        mode = "n",
        desc = "cheatsheet ask",
      },
      {
        "<leader>ar",
        function()
          require("cheatsheet").clear()
        end,
        mode = "n",
        desc = "cheatsheet clear",
      },
    },
    opts = {
      backend = {
        sandbox = "read-only",
      },
    },
  },
}
