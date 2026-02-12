local function toggle_harpoon_telescope()
  local harpoon = require "harpoon"
  local list = harpoon:list()
  local file_paths = {}

  for _, item in ipairs(list.items) do
    if item and item.value and item.value ~= "" then
      table.insert(file_paths, item.value)
    end
  end

  if #file_paths == 0 then
    vim.notify("Harpoon list is empty", vim.log.levels.INFO)
    return
  end

  local telescope_config = require("telescope.config").values

  require("telescope.pickers")
    .new({}, {
      prompt_title = "Harpoon",
      finder = require("telescope.finders").new_table {
        results = file_paths,
      },
      previewer = telescope_config.file_previewer {},
      sorter = telescope_config.generic_sorter {},
    })
    :find()
end

return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
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
        toggle_harpoon_telescope,
        desc = "harpoon telescope marks",
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
