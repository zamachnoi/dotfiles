local M = {}

M.keys = {
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
    "<leader>gl",
    function()
      Snacks.lazygit.open()
    end,
    desc = "snacks lazygit",
  },
  {
    "<leader>gL",
    function()
      Snacks.lazygit.log_file()
    end,
    desc = "snacks lazygit current file",
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
}

function M.apply()
  for _, key in ipairs(M.keys) do
    vim.keymap.set("n", key[1], key[2], { desc = key.desc, silent = true })
  end
end

return M
