require "nvchad.autocmds"

local auto_reload = vim.api.nvim_create_augroup("auto_reload_file", { clear = true })
local custom_recipes = vim.api.nvim_create_augroup("custom_recipes", { clear = true })
local lsp_hover_on_hold = vim.api.nvim_create_augroup("lsp_hover_on_hold", { clear = true })
local lspeek = require "utils.lspeek"

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = auto_reload,
  callback = function()
    if vim.fn.mode() == "c" or vim.fn.getcmdwintype() ~= "" then
      return
    end

    vim.cmd.checktime()
  end,
})

local function set_kitty_padding(value)
  if vim.fn.executable "kitty" == 1 then
    vim.fn.system { "kitty", "@", "set-spacing", "padding=" .. value }
  end
end

vim.api.nvim_create_autocmd("TermOpen", {
  group = custom_recipes,
  callback = function()
    set_kitty_padding "0"
  end,
})

vim.api.nvim_create_autocmd("TermClose", {
  group = custom_recipes,
  callback = function()
    set_kitty_padding "default"
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = custom_recipes,
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local row = mark[1]
    local col = mark[2]
    local line_count = vim.api.nvim_buf_line_count(args.buf)

    if row > 1 and row <= line_count then
      vim.api.nvim_win_set_cursor(0, { row, col })
    end
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  group = custom_recipes,
  nested = true,
  callback = function()
    if #vim.api.nvim_list_wins() == 1 and vim.bo.filetype == "NvimTree" and vim.bo.buflisted then
      vim.cmd "bw"
      vim.cmd "Nvdash"
    end
  end,
})

vim.api.nvim_create_autocmd("CursorHold", {
  group = lsp_hover_on_hold,
  callback = function(args)
    if not lspeek.is_auto_hover_enabled() then
      return
    end

    if vim.fn.mode() ~= "n" then
      return
    end

    if vim.bo[args.buf].buftype ~= "" then
      return
    end

    lspeek.peek_type_or_hover(args.buf)
  end,
})
