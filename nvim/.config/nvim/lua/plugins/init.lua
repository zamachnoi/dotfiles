local function register_norg_parser()
  local parsers = require "nvim-treesitter.parsers"

  parsers.norg = {
    install_info = {
      url = "https://github.com/nvim-neorg/tree-sitter-norg2",
      files = { "src/parser.c", "src/scanner.cc" },
      branch = "main",
    },
    filetype = "norg",
  }
end

return {
  {
    "stevearc/conform.nvim",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      register_norg_parser()

      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("CustomNorgTreesitterParser", { clear = true }),
        pattern = "TSUpdate",
        callback = register_norg_parser,
      })

      opts.ensure_installed = opts.ensure_installed or {}

      for _, parser in ipairs { "regex", "markdown", "markdown_inline" } do
        if not vim.tbl_contains(opts.ensure_installed, parser) then
          table.insert(opts.ensure_installed, parser)
        end
      end

      return opts
    end,
  },

  -- nvim-tree filewatcher
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      filesystem_watchers = {
        enable = true,
        debounce_delay = 50,
      },
    },
  },

  -- Make in-buffer git changes easier to notice than NvChad defaults.
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local gs = require "gitsigns"

      opts.attach_to_untracked = true
      opts.on_attach = function(bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end

        -- Hunk navigation
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal { "]c", bang = true }
          else
            gs.next_hunk()
          end
        end, "git next hunk")

        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal { "[c", bang = true }
          else
            gs.prev_hunk()
          end
        end, "git prev hunk")

        -- Hunk actions
        map({ "n", "x" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", "git stage hunk")
        map({ "n", "x" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "git reset hunk")
        map("n", "<leader>gS", gs.stage_buffer, "git stage buffer")
        map("n", "<leader>gR", gs.reset_buffer, "git reset buffer")
        map("n", "<leader>gu", gs.undo_stage_hunk, "git undo stage hunk")

        -- Inspect changes
        map("n", "<leader>gp", gs.preview_hunk, "git preview hunk")
        map("n", "<leader>gb", gs.blame_line, "git blame line")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "git toggle line blame")
        map("n", "<leader>gd", gs.diffthis, "git diff this")
        map("n", "<leader>gD", function()
          gs.diffthis "~"
        end, "git diff this (~)")

        -- Lists and views
        map("n", "<leader>gq", gs.setqflist, "git hunks to quickfix")
        map("n", "<leader>gQ", gs.setloclist, "git hunks to loclist")
        map("n", "<leader>gx", gs.toggle_deleted, "git toggle deleted")

        -- Text object
        map({ "o", "x" }, "ih", gs.select_hunk, "git select hunk")
      end

      return opts
    end,
  },
}
