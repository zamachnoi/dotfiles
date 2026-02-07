require "nvchad.autocmds"

local auto_reload = vim.api.nvim_create_augroup("auto_reload_file", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = auto_reload,
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd "checktime"
    end
  end,
})
