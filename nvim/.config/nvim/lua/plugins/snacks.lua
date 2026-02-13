return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    keys = {
      {
        "<leader>fw",
        function()
          Snacks.picker.grep({
            hidden = true,
            exclude = {
              ".git/*",
              ".git/**",
            },
          })
        end,
        desc = "snacks live grep (hidden, no .git)",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "snacks find buffers",
      },
      {
        "<leader>fh",
        function()
          Snacks.picker.help()
        end,
        desc = "snacks help page",
      },
      {
        "<leader>ma",
        function()
          Snacks.picker.marks()
        end,
        desc = "snacks find marks",
      },
      {
        "<leader>fo",
        function()
          Snacks.picker.recent()
        end,
        desc = "snacks find oldfiles",
      },
      {
        "<leader>fz",
        function()
          Snacks.picker.lines()
        end,
        desc = "snacks find in current buffer",
      },
      {
        "<leader>cm",
        function()
          Snacks.picker.git_log()
        end,
        desc = "snacks git commits",
      },
      {
        "<leader>gt",
        function()
          Snacks.picker.git_status()
        end,
        desc = "snacks git status",
      },
      {
        "<leader>pt",
        function()
          Snacks.picker.buffers({
            title = "Terminal Buffers",
            hidden = true,
            nofile = true,
            filter = {
              filter = function(item)
                return item.buftype == "terminal"
              end,
            },
          })
        end,
        desc = "snacks pick hidden term",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.smart()
        end,
        desc = "snacks smart find files",
      },
      {
        "<leader>fa",
        function()
          Snacks.picker.files({
            follow = true,
            ignored = true,
            hidden = true,
          })
        end,
        desc = "snacks find all files",
      },
    },
    opts = {
      bigfile = { enabled = true },
      image = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true },
      picker = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      words = { enabled = true },
    },
  },
}
