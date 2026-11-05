-- Loaded via `nvim -c 'luafile boot_check.lua' FILE` (see verify.sh). After BOOT_WAIT ms it
-- writes a report to $BOOT_OUT and quits. Lines starting with FAIL make verify.sh exit 1.
vim.defer_fn(function()
  local o = {}
  local function add(...) table.insert(o, table.concat(vim.tbl_map(tostring, { ... }), " ")) end
  local buf = vim.api.nvim_get_current_buf()

  add("filetype:", vim.bo.filetype)
  add("lsp:", table.concat(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients { bufnr = buf }), ","))

  -- Treesitter: count real highlight captures. A highlighter can be "active" with zero
  -- captures when the highlight queries are missing (e.g. broken site/queries links).
  local active = vim.treesitter.highlighter.active[buf] ~= nil
  local captures, langs = 0, {}
  for row = 0, math.min(vim.api.nvim_buf_line_count(buf), 60) - 1 do
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    for col = 0, #line - 1, 4 do
      for _, c in ipairs(vim.treesitter.get_captures_at_pos(buf, row, col)) do
        captures = captures + 1
        langs[c.lang] = true
      end
    end
  end
  add("treesitter:", active and "active" or "inactive", "captures=" .. captures, "langs=" .. table.concat(vim.tbl_keys(langs), ","))
  if active and captures == 0 then add "FAIL: treesitter active but no highlight captures (missing queries?)" end
  for _, lang in ipairs(vim.tbl_keys(langs)) do
    if #vim.treesitter.query.get_files(lang, "highlights") == 0 then add("FAIL: no highlights query for " .. lang) end
  end

  local ok_lazy, lazy = pcall(require, "lazy.core.config")
  if ok_lazy then
    local n = 0
    for _, p in pairs(lazy.plugins) do if p._.loaded then n = n + 1 end end
    add("plugins loaded:", n)
  end

  local msgs = vim.trim(vim.fn.execute "messages")
  add("errmsg:", vim.v.errmsg)
  add("messages:", msgs == "" and "(none)" or ("\n" .. msgs))
  if msgs:find "E%d+:" or msgs:find "Error" or msgs:find "stack traceback" then add "FAIL: errors in :messages" end

  vim.fn.writefile(vim.split(table.concat(o, "\n"), "\n"), vim.env.BOOT_OUT)
  vim.cmd "qa!"
end, tonumber(vim.env.BOOT_WAIT or "6000"))
