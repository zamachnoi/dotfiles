local M = {}

local function normalize_message(diagnostic)
  local message = diagnostic.message:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

  if diagnostic.source and diagnostic.source ~= "" then
    return string.format("[%s] %s", diagnostic.source, message)
  end

  return message
end

local function copy_to_registers(text)
  if vim.fn.has("clipboard") == 1 then
    vim.fn.setreg("+", text)
  end

  vim.fn.setreg('"', text)
end

function M.copy_current_line()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diagnostics = vim.diagnostic.get(0, { lnum = lnum })

  if #diagnostics == 0 then
    vim.notify("No diagnostics on current line", vim.log.levels.INFO)
    return
  end

  local messages = {}

  for _, diagnostic in ipairs(diagnostics) do
    table.insert(messages, normalize_message(diagnostic))
  end

  copy_to_registers(table.concat(messages, "\n"))
  vim.notify("Copied diagnostics on current line", vim.log.levels.INFO)
end

function M.copy_current_file()
  local diagnostics = vim.diagnostic.get(0)

  if #diagnostics == 0 then
    vim.notify("No diagnostics in current file", vim.log.levels.INFO)
    return
  end

  table.sort(diagnostics, function(a, b)
    if a.lnum == b.lnum then
      return a.col < b.col
    end
    return a.lnum < b.lnum
  end)

  local messages = {}

  for _, diagnostic in ipairs(diagnostics) do
    table.insert(messages, string.format("L%d: %s", diagnostic.lnum + 1, normalize_message(diagnostic)))
  end

  copy_to_registers(table.concat(messages, "\n"))
  vim.notify("Copied diagnostics for current file", vim.log.levels.INFO)
end

return M
