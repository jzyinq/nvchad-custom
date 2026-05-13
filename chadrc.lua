---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require "custom.highlights"
local writer_mode = require "custom.writer_mode"

-- Load obsidian module (registers autocommands for overdue tasks indicator)
require "custom.obsidian"

M.ui = {
  theme = "onedark",
  theme_toggle = { "bearded-arc", "one_light" },
  statusline = {
    overriden_modules = function(modules)
      table.insert(modules, 11, writer_mode.statusline_segment())
    end,
  },

  hl_override = highlights.override,
  hl_add = highlights.add,
  nvdash = {
    load_on_startup = false,
    header = {
      "                                                     ",
      "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
      "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
      "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
      "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
      "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
      "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
      "                                                     ",
    },
    buttons = {
      { "󱃸  Find Projects", "Spc f p", "Telescope project" },
      { "  Find File", "Spc f f", "Telescope find_files" },
      { "  Configure NvChad", "Spc c n", "edit ~/.config/nvim/chadrc.lua" },
    },
  },
}

M.plugins = "custom.plugins"
-- check core.mappings for table structure
M.mappings = require "custom.mappings"

return M
