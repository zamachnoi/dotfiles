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

map({ "n", "v" }, "<leader>gR", "<cmd>Gitsigns reset_hunk<CR>", { desc = "git reset hunk" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
