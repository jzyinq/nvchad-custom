require "nvchad.mappings"

-- Keymaps are still defined as NvChad v2.0-style tables in lua/custom/mappings.lua:
--   M.<section> = { <mode> = { [lhs] = { rhs, desc, opts = {...} } } }
--   M.disabled  = { <mode> = { [lhs] = "" } }   -- removes a NvChad default
-- This loader turns them into vim.keymap.set calls.
local tables = require "custom.mappings"

for mode, keys in pairs(tables.disabled or {}) do
  for lhs in pairs(keys) do
    pcall(vim.keymap.del, mode, lhs)
  end
end

for name, section in pairs(tables) do
  if name ~= "disabled" then
    for mode, keys in pairs(section) do
      for lhs, info in pairs(keys) do
        local opts = vim.tbl_extend("force", { desc = info[2] }, info.opts or {})
        vim.keymap.set(mode, lhs, info[1], opts)
      end
    end
  end
end
