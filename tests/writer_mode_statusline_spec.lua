local repo_root = vim.fn.getcwd()
local writer_mode = dofile(repo_root .. "/writer_mode.lua")

local function assert_equal(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s\nexpected: %s\nactual: %s", label, expected, tostring(actual)))
  end
end

local original_wordcount = vim.fn.wordcount
local original_writer_mode = vim.g.writer_mode

vim.fn.wordcount = function()
  return { words = 20 }
end

vim.g.writer_mode = false
assert_equal(writer_mode.statusline_segment(), "", "returns empty string when writer mode is disabled")

vim.g.writer_mode = true
assert_equal(
  writer_mode.statusline_segment(),
  "%#St_gitIcons# 20/750 ",
  "renders default segment below threshold"
)

vim.fn.wordcount = function()
  return { words = 750 }
end

assert_equal(
  writer_mode.statusline_segment(),
  "%#St_lspInfo# 750/750 ",
  "renders success segment at threshold"
)

vim.fn.wordcount = original_wordcount
vim.g.writer_mode = original_writer_mode
