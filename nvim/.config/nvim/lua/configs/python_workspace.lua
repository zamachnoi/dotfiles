local M = {}

local function normalize(path)
  if not path or path == "" then
    return nil
  end

  return path:gsub("\\", "/")
end

local function find_segment_root(path, segment)
  path = normalize(path)
  if not path then
    return nil
  end

  local marker = "/" .. segment .. "/"
  local idx = nil
  local start = 1

  while true do
    local next_idx = path:find(marker, start, true)
    if not next_idx then
      break
    end

    idx = next_idx
    start = next_idx + 1
  end

  if idx then
    return path:sub(1, idx + #segment)
  end

  local suffix = "/" .. segment
  if path:sub(-#suffix) == suffix then
    return path
  end

  return nil
end

local function is_executable(path)
  return path and vim.fn.executable(path) == 1
end

function M.find_orb_root(path)
  return find_segment_root(path, "orb-res-app")
end

function M.find_llm_root(path)
  return find_segment_root(path, "llm_query_tool") or find_segment_root(path, "llm-query-tool")
end

function M.orb_context(path)
  local normalized = normalize(path)
  local root = M.find_orb_root(normalized)
  if not normalized or not root then
    return nil
  end

  local rel = normalized:sub(#root + 2)
  if rel == "" then
    return nil
  end

  if rel == "backend" or rel:match("^backend/") then
    return "backend"
  end

  if rel == "cron" or rel:match("^cron/") then
    return "cron"
  end

  if rel == "hypervisor-agent" or rel:match("^hypervisor%-agent/") then
    return "hypervisor-agent"
  end

  if rel == "shared" or rel:match("^shared/") then
    return "shared"
  end

  return nil
end

function M.is_orb_file(path)
  return M.orb_context(path) ~= nil
end

function M.is_llm_file(path)
  return M.find_llm_root(path) ~= nil
end

function M.orb_python(path)
  local root = M.find_orb_root(path)
  if not root then
    return nil
  end

  local orb_python = root .. "/_gen_venv/bin/python"
  if is_executable(orb_python) then
    return orb_python
  end

  return nil
end

function M.resolve_llm_tool(path, exe_name)
  local root = M.find_llm_root(path)
  if root then
    local venv_tool = root .. "/.venv/bin/" .. exe_name
    if is_executable(venv_tool) then
      return venv_tool
    end
  end

  return exe_name
end

return M
