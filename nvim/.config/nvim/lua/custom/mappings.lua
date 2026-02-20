local map = vim.keymap.set

map("n", "<leader>tn", ":tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tl", "gt", { desc = "Next tab" })
map("n", "<leader>th", "gT", { desc = "Prev tab" })
