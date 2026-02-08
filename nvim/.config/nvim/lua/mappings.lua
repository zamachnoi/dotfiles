-- ~/.config/nvim/lua/mappings.lua

require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
local del = vim.keymap.del

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Remove NvChad default window navigation maps and use tmux navigator instead.
del("n", "<C-h>")
del("n", "<C-j>")
del("n", "<C-k>")
del("n", "<C-l>")

map("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", { silent = true, desc = "tmux navigate left" })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", { silent = true, desc = "tmux navigate down" })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", { silent = true, desc = "tmux navigate up" })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", { silent = true, desc = "tmux navigate right" })
map("n", "<C-\\>", "<cmd>TmuxNavigatePrevious<CR>", { silent = true, desc = "tmux navigate previous" })

map({ "n", "v" }, "<leader>gR", "<cmd>Gitsigns reset_hunk<CR>", { desc = "git reset hunk" })

map({ "n", "v" }, "<leader>mp", "<cmd>MarkdownPreview<CR>", { desc = "markdown preview" })

local builtin = require "telescope.builtin"

vim.keymap.set("n", "<leader>fw", function()
  builtin.live_grep {
    additional_args = function()
      return {
        "--hidden", -- include dotfiles
        "--glob=!.git/*", -- exclude .git
        "--glob=!.git/**", -- exclude .git recursively
      }
    end,
  }
end, { desc = "telescope live grep (hidden, no .git)" })
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
