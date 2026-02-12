local api = vim.api
local util = vim.lsp.util

local M = {}

-- Defaults: manual peek is preferred, auto-hover stays opt-in.
M.auto_hover_enabled = false

local FOCUS_ID = {
  peek = "lsp_type_peek",
  hover = "textDocument/hover",
}

local METHOD = {
  hover = "textDocument/hover",
  type_definition = "textDocument/typeDefinition",
}

local function normalize_bufnr(bufnr)
  if not bufnr or bufnr == 0 then
    return api.nvim_get_current_buf()
  end

  return bufnr
end

local function float_size()
  local max_width = math.floor(vim.o.columns * 0.75)
  local max_height = math.floor(vim.o.lines * 0.8)

  return {
    max_width = math.max(max_width, 100),
    max_height = math.max(max_height, 30),
  }
end

local function float_opts(focus_id)
  local size = float_size()

  return {
    border = "rounded",
    focusable = false,
    focus_id = focus_id,
    max_width = size.max_width,
    max_height = size.max_height,
  }
end

local function first_lsp_location(result)
  if type(result) ~= "table" then
    return nil
  end

  if result.uri or result.targetUri then
    return result
  end

  if vim.islist(result) and #result > 0 then
    return result[1]
  end

  return nil
end

local function first_lsp_location_from_responses(responses)
  for _, response in pairs(responses) do
    local location = first_lsp_location(response and response.result)
    if location then
      return location
    end
  end

  return nil
end

local function location_uri(location)
  return location.targetUri or location.uri
end

local function location_range(location)
  return location.targetRange or location.range
end

local function get_location_bufnr(location)
  local uri = location_uri(location)
  if not uri then
    return nil
  end

  local bufnr = vim.uri_to_bufnr(uri)
  if not api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)
  end

  return bufnr
end

local function buffer_syntax(bufnr)
  local syntax = vim.bo[bufnr].syntax
  if syntax == "" then
    return vim.bo[bufnr].filetype
  end

  return syntax
end

local function set_float_highlighting(source_bufnr, float_bufnr)
  if not float_bufnr or not api.nvim_buf_is_valid(float_bufnr) then
    return
  end

  local ft = vim.bo[source_bufnr].filetype
  if ft == "" then
    return
  end

  vim.bo[float_bufnr].filetype = ft
  pcall(vim.treesitter.start, float_bufnr, ft)
end

local function open_lines_preview(source_bufnr, lines, focus_id)
  if #lines == 0 then
    return nil
  end

  local float_bufnr = util.open_floating_preview(lines, buffer_syntax(source_bufnr), float_opts(focus_id))
  set_float_highlighting(source_bufnr, float_bufnr)
  return float_bufnr
end

local function find_block_end(bufnr, start_line)
  local line_count = api.nvim_buf_line_count(bufnr)
  local depth = 0
  local seen_open = false

  for lnum = start_line, line_count - 1 do
    local line = api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ""

    for ch in line:gmatch "[{}]" do
      if ch == "{" then
        depth = depth + 1
        seen_open = true
      elseif seen_open then
        depth = depth - 1
        if depth == 0 then
          return lnum
        end
      end
    end
  end

  return nil
end

local function open_expanded_type_block(location)
  local bufnr = get_location_bufnr(location)
  local range = location_range(location)
  if not bufnr or not range then
    return false
  end

  local start_line = range.start.line
  local header_line = api.nvim_buf_get_lines(bufnr, start_line, start_line + 1, false)[1] or ""
  if not header_line:find("{", 1, true) then
    return false
  end

  local end_line = find_block_end(bufnr, start_line)
  if not end_line or end_line < start_line then
    return false
  end

  local lines = api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
  return open_lines_preview(bufnr, lines, FOCUS_ID.peek) ~= nil
end

local function open_location_preview(location)
  local bufnr = get_location_bufnr(location)
  local range = location_range(location)
  if not bufnr or not range then
    return false
  end

  local lines = api.nvim_buf_get_lines(bufnr, range.start.line, range["end"].line + 1, false)
  return open_lines_preview(bufnr, lines, FOCUS_ID.peek) ~= nil
end

local function clients_for_method(bufnr, method)
  return vim.lsp.get_clients { bufnr = bufnr, method = method }
end

local function find_window_by_focus_id(focus_id)
  for _, win in ipairs(api.nvim_list_wins()) do
    local ok = pcall(api.nvim_win_get_var, win, focus_id)
    if ok then
      return win
    end
  end

  return nil
end

---Show LSP hover in a float without noisy "No information available" notifications.
function M.hover()
  vim.lsp.buf.hover(vim.tbl_extend("force", float_opts(nil), { silent = true }))
end

---Peek type definition in a float, with hover fallback when no type result is returned.
---@param bufnr? integer
---@return boolean started
function M.peek_type_or_hover(bufnr)
  bufnr = normalize_bufnr(bufnr)

  local type_clients = clients_for_method(bufnr, METHOD.type_definition)
  local hover_clients = clients_for_method(bufnr, METHOD.hover)

  if #type_clients == 0 and #hover_clients == 0 then
    return false
  end

  if #type_clients > 0 then
    local position_encoding = type_clients[1].offset_encoding or "utf-16"
    local params = util.make_position_params(0, position_encoding)

    vim.lsp.buf_request_all(bufnr, METHOD.type_definition, params, function(responses)
      local location = first_lsp_location_from_responses(responses)
      if location then
        if open_expanded_type_block(location) then
          return
        end

        open_location_preview(location)
        return
      end

      if #hover_clients > 0 then
        M.hover()
      end
    end)

    return true
  end

  if #hover_clients > 0 then
    M.hover()
    return true
  end

  return false
end

---Toggle peek float visibility: open on first press, close on second press.
---@param bufnr? integer
---@return boolean opened
function M.toggle_peek_type_or_hover(bufnr)
  local win = find_window_by_focus_id(FOCUS_ID.peek) or find_window_by_focus_id(FOCUS_ID.hover)
  if win and api.nvim_win_is_valid(win) then
    api.nvim_win_close(win, true)
    return false
  end

  return M.peek_type_or_hover(bufnr)
end

function M.is_auto_hover_enabled()
  return M.auto_hover_enabled
end

function M.toggle_auto_hover()
  M.auto_hover_enabled = not M.auto_hover_enabled
  local status = M.auto_hover_enabled and "enabled" or "disabled"
  vim.notify("LSP auto hover " .. status, vim.log.levels.INFO)
  return M.auto_hover_enabled
end

return M
