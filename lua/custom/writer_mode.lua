local M = {}

local THRESHOLD = 750
local DEFAULT_HL = "St_gitIcons"
local SUCCESS_HL = "St_lspInfo"

function M.statusline_segment()
  if not vim.g.writer_mode then
    return ""
  end

  local wordcount = vim.fn.wordcount()
  local count = type(wordcount) == "table" and tonumber(wordcount.words) or 0
  count = count or 0

  local group = count >= THRESHOLD and SUCCESS_HL or DEFAULT_HL

  return string.format("%%#%s# %d/%d ", group, count, THRESHOLD)
end

return M
