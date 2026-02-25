local M = {}

local lint = require("lint")
local workspace = require("configs.python_workspace")

local severity = vim.diagnostic.severity

local function github_severity(level)
  if level == "error" then
    return severity.ERROR
  end

  if level == "warning" then
    return severity.WARN
  end

  return severity.INFO
end

local function parse_github_annotations(output, source)
  local diagnostics = {}

  for line in output:gmatch("[^\r\n]+") do
    local level, filename, line_nr, col_nr, message =
      line:match("^::(%w+) .-,file=([^,]+),line=(%d+),col=(%d+),.-::(.+)$")

    if level and filename and line_nr and col_nr and message then
      message = message:gsub("^[^:]+:%d+:%d+:%s*", "")
      table.insert(diagnostics, {
        filename = filename,
        lnum = tonumber(line_nr) - 1,
        col = tonumber(col_nr) - 1,
        severity = github_severity(level),
        source = source,
        message = message,
      })
    end
  end

  return diagnostics
end

local function parse_mypy(output, source)
  local diagnostics = {}

  for line in output:gmatch("[^\r\n]+") do
    local filename, line_nr, col_nr, kind, message = line:match("^([^:]+):(%d+):(%d+): (%a+): (.+)$")

    if not filename then
      filename, line_nr, kind, message = line:match("^([^:]+):(%d+): (%a+): (.+)$")
      col_nr = "1"
    end

    if filename and line_nr and col_nr and kind and message then
      local diag_severity = severity.WARN
      if kind == "error" then
        diag_severity = severity.ERROR
      elseif kind == "note" then
        diag_severity = severity.INFO
      end

      table.insert(diagnostics, {
        filename = filename,
        lnum = tonumber(line_nr) - 1,
        col = tonumber(col_nr) - 1,
        severity = diag_severity,
        source = source,
        message = message,
      })
    end
  end

  return diagnostics
end

local function parse_pylint(output, source)
  local diagnostics = {}

  for line in output:gmatch("[^\r\n]+") do
    local filename, line_nr, col_nr, code, message, rule =
      line:match("^([^:]+):(%d+):(%d+): ([CRWEF]%d+): (.+) %(([^)]+)%)$")

    if filename and line_nr and col_nr and code and message then
      local lead = code:sub(1, 1)
      local diag_severity = severity.WARN
      if lead == "E" or lead == "F" then
        diag_severity = severity.ERROR
      end

      if rule and rule ~= "" then
        message = string.format("%s (%s)", message, rule)
      end

      table.insert(diagnostics, {
        filename = filename,
        lnum = tonumber(line_nr) - 1,
        col = tonumber(col_nr) - 1,
        severity = diag_severity,
        source = source,
        message = message,
      })
    end
  end

  return diagnostics
end

local function current_bufname()
  return vim.api.nvim_buf_get_name(0)
end

local function orb_python_cmd()
  return workspace.orb_python(current_bufname()) or "python3"
end

local function llm_tool_cmd(exe_name)
  return workspace.resolve_llm_tool(current_bufname(), exe_name)
end

local function make_orb_mypy_linter(source_name)
  return {
    cmd = "sh",
    stdin = false,
    append_fname = true,
    ignore_exitcode = true,
    stream = "stdout",
    args = {
      "-c",
      function()
        local python = vim.fn.shellescape(orb_python_cmd())
        return table.concat({
          python .. " -m mypy",
          "--soft-error-limit=-1",
          "--cache-dir=./_gen_mypy_cache",
          "--show-column-numbers",
          "--follow-imports=silent",
          '"$0"',
          "2>&1",
          "|",
          python .. " -m mypy_baseline filter",
          "--baseline-path mypy-baseline.txt",
          "--allow-unsynced",
          "--hide-stats",
        }, " ")
      end,
    },
    parser = function(output)
      return parse_mypy(output, source_name)
    end,
  }
end

local function make_orb_pylint_linter(source_name)
  return {
    cmd = orb_python_cmd,
    stdin = false,
    append_fname = true,
    ignore_exitcode = true,
    stream = "stdout",
    args = {
      "-m",
      "pylint",
      "--reports=no",
      "--persistent=n",
    },
    parser = function(output)
      return parse_pylint(output, source_name)
    end,
  }
end

local function register_linters()
  lint.linters.mypy_orb = make_orb_mypy_linter("mypy")
  lint.linters.pylint_orb = make_orb_pylint_linter("pylint")

  lint.linters.ruff_llm = {
    cmd = function()
      return llm_tool_cmd("ruff")
    end,
    stdin = false,
    append_fname = true,
    ignore_exitcode = true,
    stream = "stdout",
    args = {
      "check",
      "--output-format",
      "github",
    },
    parser = function(output)
      return parse_github_annotations(output, "ruff")
    end,
  }

  lint.linters.ty_llm = {
    cmd = function()
      return llm_tool_cmd("ty")
    end,
    stdin = false,
    append_fname = true,
    ignore_exitcode = true,
    stream = "stdout",
    args = {
      "check",
      "--output-format",
      "github",
    },
    parser = function(output)
      return parse_github_annotations(output, "ty")
    end,
  }
end

local function linters_for(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return nil
  end

  local orb_context = workspace.orb_context(filename)
  if orb_context then
    return { "mypy_orb", "pylint_orb" }
  end

  if workspace.is_llm_file(filename) then
    return { "ruff_llm", "ty_llm" }
  end

  return nil
end

local function lint_cwd(filename)
  return workspace.find_orb_root(filename) or workspace.find_llm_root(filename)
end

local function maybe_lint(args)
  local bufnr = args.buf
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" or not filename:match("%.pyi?$") then
    return
  end

  local names = linters_for(bufnr)
  if not names or #names == 0 then
    return
  end

  local cwd = lint_cwd(filename)

  vim.api.nvim_buf_call(bufnr, function()
    if cwd then
      lint.try_lint(names, { cwd = cwd })
      return
    end

    lint.try_lint(names)
  end)
end

function M.setup()
  register_linters()

  local group = vim.api.nvim_create_augroup("PythonWorkspaceLint", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "BufNewFile" }, {
    group = group,
    callback = maybe_lint,
  })
end

return M
