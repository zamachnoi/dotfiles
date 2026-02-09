-- ~/.config/nvim/lua/mappings.lua

require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
local del = vim.keymap.del

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

local function toggle_lsp_for_current_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients { bufnr = bufnr }

  if #clients > 0 then
    local detached_client_ids = {}

    for _, client in ipairs(clients) do
      if vim.lsp.buf_is_attached(bufnr, client.id) then
        vim.lsp.buf_detach_client(bufnr, client.id)
        table.insert(detached_client_ids, client.id)
      end
    end

    vim.b[bufnr].lsp_toggled_off_client_ids = detached_client_ids
    vim.notify("LSP disabled for current buffer", vim.log.levels.INFO)
    return
  end

  local reattached = 0
  local detached_client_ids = vim.b[bufnr].lsp_toggled_off_client_ids or {}

  for _, client_id in ipairs(detached_client_ids) do
    local client = vim.lsp.get_client_by_id(client_id)
    if client and not vim.lsp.buf_is_attached(bufnr, client_id) then
      local ok = pcall(vim.lsp.buf_attach_client, bufnr, client_id)
      if ok and vim.lsp.buf_is_attached(bufnr, client_id) then
        reattached = reattached + 1
      end
    end
  end

  vim.b[bufnr].lsp_toggled_off_client_ids = nil

  if reattached == 0 then
    pcall(vim.cmd, "LspStart")
  end

  if #vim.lsp.get_clients { bufnr = bufnr } > 0 then
    vim.notify("LSP enabled for current buffer", vim.log.levels.INFO)
  else
    vim.notify("No LSP server available for this buffer", vim.log.levels.WARN)
  end
end

map("n", "<leader>ul", toggle_lsp_for_current_buffer, { desc = "toggle lsp (buffer)" })

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
