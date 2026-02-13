local map = vim.keymap.set
local del = vim.keymap.del
local lspeek = require("utils.lspeek")
local diagnostics = require("utils.diagnostics")

require("nvchad.mappings")
vim.schedule(function()
  require("utils.snacks_keys").apply()
end)

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

local function toggle_lsp_for_current_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

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
    pcall(function()
      vim.cmd("LspStart")
    end)
  end

  if #vim.lsp.get_clients({ bufnr = bufnr }) > 0 then
    vim.notify("LSP enabled for current buffer", vim.log.levels.INFO)
  else
    vim.notify("No LSP server available for this buffer", vim.log.levels.WARN)
  end
end

map("n", "<leader>ul", toggle_lsp_for_current_buffer, { desc = "toggle lsp (buffer)" })
map("n", "<leader>dy", diagnostics.copy_current_line, { desc = "copy line diagnostics" })
map("n", "<leader>dY", diagnostics.copy_current_file, { desc = "copy file diagnostics" })
map("n", "<leader>lh", function()
  lspeek.toggle_auto_hover()
end, { desc = "toggle auto hover" })
map("n", "<C-p>", function()
  lspeek.toggle_peek_type_or_hover(0)
end, { desc = "toggle type peek" })

-- Keep <leader>h free for plugin prefixes and move NvChad horizontal terminal to <leader>j.
pcall(del, "n", "<leader>h")
pcall(del, "n", "<leader>j")
map("n", "<leader>j", function()
  require("nvchad.term").new({ pos = "sp" })
end, { desc = "terminal new horizontal term" })
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
