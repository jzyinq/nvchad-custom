-- Structure follows nvconfig.lua: https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

local highlights = require "custom.highlights"
local writer_mode = require "custom.writer_mode"

M.base46 = {
  theme = "onedark",
  theme_toggle = { "onedark", "chocolate" },
  hl_override = highlights.override,
  hl_add = highlights.add,
}

M.ui = {
  statusline = {
    -- default order + writer mode word count at the end
    order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cwd", "cursor", "writer" },
    modules = {
      writer = writer_mode.statusline_segment,
    },
  },
}

M.nvdash = {
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
    { txt = "󱃸  Find Projects", keys = "fp", cmd = "Telescope project" },
    { txt = "  Find File", keys = "ff", cmd = "Telescope find_files" },
    { txt = "  Configure NvChad", keys = "cn", cmd = "edit ~/.config/nvim/lua/chadrc.lua" },
  },
}

-- floating terminal (<A-i>): was configured on nvterm in v2.0
M.term = {
  float = { row = 0.1, col = 0.05, width = 0.9, height = 0.8 },
}

-- colour highlighting: #rrggbb, plus rgb()/hsl() etc. reported by LSP (e.g. cssls)
-- "virtual" = small coloured swatch before the code; also "bg" / "fg"
M.colorify = { enabled = true, mode = "virtual" }

-- installed by :MasonInstallAll
M.mason = {
  -- same set as the old config's mason install
  pkgs = {
    "basedpyright",
    "bash-language-server",
    "clang-format",
    "clangd",
    "css-lsp",
    "deno",
    "go-debug-adapter",
    "gofumpt",
    "goimports",
    "golangci-lint",
    "golines",
    "gopls",
    "helm-ls",
    "html-lsp",
    "json-lsp",
    "lua-language-server",
    "marksman",
    "nilaway",
    "prettier",
    "pyright",
    "ruff",
    "shellcheck",
    "stylua",
    "tilt",
    "typescript-language-server",
    "vtsls",
    "yaml-language-server",
  },
}

return M
