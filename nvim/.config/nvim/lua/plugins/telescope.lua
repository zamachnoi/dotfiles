return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>fw",
        function()
          require("telescope.builtin").live_grep {
            additional_args = function()
              return {
                "--hidden",
                "--glob=!.git/*",
                "--glob=!.git/**",
              }
            end,
          }
        end,
        desc = "telescope live grep (hidden, no .git)",
      },
    },
  },
}
