local function toggle_harpoon_picker()
  local harpoon = require "harpoon"
  local list = harpoon:list()
  local items = {}

  for _, item in ipairs(list.items) do
    if item and item.value and item.value ~= "" then
      table.insert(items, {
        file = item.value,
        text = item.value,
      })
    end
  end

  if #items == 0 then
    vim.notify("Harpoon list is empty", vim.log.levels.INFO)
    return
  end

  Snacks.picker {
    title = "Harpoon",
    items = items,
    format = "file",
    preview = "file",
    confirm = function(picker, item)
      picker:close()
      if item and item.file then
        vim.cmd.edit(vim.fn.fnameescape(item.file))
      end
    end,
  }
end

return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {},
    keys = {
      {
        "<leader>ha",
        function()
          require("harpoon"):list():add()
        end,
        desc = "harpoon add file",
      },
      {
        "<leader>hm",
        function()
          local harpoon = require "harpoon"
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "harpoon quick menu",
      },
      {
        "<leader>hh",
        toggle_harpoon_picker,
        desc = "harpoon marks picker",
      },
      {
        "<leader>h1",
        function()
          require("harpoon"):list():select(1)
        end,
        desc = "harpoon go to file 1",
      },
      {
        "<leader>h2",
        function()
          require("harpoon"):list():select(2)
        end,
        desc = "harpoon go to file 2",
      },
      {
        "<leader>h3",
        function()
          require("harpoon"):list():select(3)
        end,
        desc = "harpoon go to file 3",
      },
      {
        "<leader>h4",
        function()
          require("harpoon"):list():select(4)
        end,
        desc = "harpoon go to file 4",
      },
      {
        "<leader>hn",
        function()
          require("harpoon"):list():next()
        end,
        desc = "harpoon next file",
      },
      {
        "<leader>hp",
        function()
          require("harpoon"):list():prev()
        end,
        desc = "harpoon previous file",
      },
    },
  },
}
