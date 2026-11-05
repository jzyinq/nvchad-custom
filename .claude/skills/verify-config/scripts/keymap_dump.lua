-- Loaded via `nvim -c 'luafile keymap_dump.lua' FILE`; writes every keymap (global "G" and
-- buffer-local "B") and every plugin's load state to $BOOT_OUT, sorted, then quits.
-- Diff two dumps (e.g. before/after a change, or two NVIM_APPNAMEs) to see what changed.
vim.defer_fn(function()
  local lines = {}
  for _, mode in ipairs { "n", "v", "x", "s", "o", "i", "c", "t" } do
    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
      table.insert(lines, ("G %s %s  -- %s"):format(mode, m.lhs:gsub(" ", "<leader>"), m.desc or m.rhs or ""))
    end
    for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
      table.insert(lines, ("B %s %s  -- %s"):format(mode, m.lhs:gsub(" ", "<leader>"), m.desc or m.rhs or ""))
    end
  end
  local ok, lazy = pcall(require, "lazy.core.config")
  for name, p in pairs(ok and lazy.plugins or {}) do
    table.insert(lines, ("P %s %s"):format(name, p._.loaded and "loaded" or "lazy"))
  end
  table.sort(lines)
  vim.fn.writefile(lines, vim.env.BOOT_OUT)
  vim.cmd "qa!"
end, tonumber(vim.env.BOOT_WAIT or "6000"))
