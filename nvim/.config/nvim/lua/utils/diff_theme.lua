local M = {}

local function get_palette()
  local ok_base46, base46 = pcall(require, "base46")
  local ok_colors, color_utils = pcall(require, "base46.colors")

  if not ok_base46 or not ok_colors then
    return nil, nil
  end

  return base46.get_theme_tb("base_30"), color_utils.mix
end

function M.apply()
  local colors, mix = get_palette()

  if not colors then
    return
  end

  local function tint(color, strength)
    return mix(colors.black, color, strength)
  end

  local add = { fg = colors.green, bg = tint(colors.green, 18) }
  local change = { fg = colors.light_grey, bg = tint(colors.blue, 14) }
  local delete = { fg = colors.red, bg = tint(colors.red, 18) }
  local text = { fg = colors.white, bg = tint(colors.blue, 32), bold = true }
  local delete_dim = { fg = colors.grey_fg2, bg = tint(colors.red, 7) }

  local groups = {
    DiffAdd = add,
    DiffAdded = add,
    DiffChange = change,
    DiffDelete = delete,
    DiffRemoved = delete,
    DiffText = text,

    diffAdded = { fg = colors.green },
    diffChanged = { fg = colors.yellow },
    diffRemoved = { fg = colors.red },

    DiffviewDiffAdd = add,
    DiffviewDiffAddAsDelete = delete,
    DiffviewDiffChange = change,
    DiffviewDiffDelete = delete,
    DiffviewDiffDeleteDim = delete_dim,
    DiffviewDiffText = text,
  }

  for group, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
