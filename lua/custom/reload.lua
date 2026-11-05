-- Soft-reload the custom config without restarting nvim.
-- Reloads: custom/init.lua (options, autocmds), all custom.* modules,
-- chadrc + mappings, theme/highlights.
-- Does NOT re-apply plugin specs from plugins.lua (lazy.nvim can't); for
-- those use `:Lazy reload <plugin>` or restart nvim.
local M = {}

function M.reload()
  -- 1. drop cached custom modules so the next require() picks up edits
  for name in pairs(package.loaded) do
    if name == "custom" or name:match "^custom%." then
      package.loaded[name] = nil
    end
  end

  -- 2. options and autocmds (same way init.lua loads it)
  local init_path = vim.api.nvim_get_runtime_file("lua/custom/init.lua", false)[1]
  if init_path then
    local ok, err = pcall(dofile, init_path)
    if not ok then
      vim.notify("custom/init.lua: " .. err, vim.log.levels.ERROR)
      return
    end
  end

  -- 3. chadrc (ui options) + all keymaps
  local config = require("core.utils").load_config()
  vim.g.nvchad_theme = config.ui.theme
  vim.g.transparency = config.ui.transparency
  require("core.utils").load_mappings()

  -- 4. theme / highlights
  require("plenary.reload").reload_module "base46"
  require("base46").load_all_highlights()

  vim.notify "Config reloaded (plugin specs need :Lazy reload or restart)"
end

return M
