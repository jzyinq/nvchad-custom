local cwd = vim.fn.getcwd()
package.path = cwd .. "/?.lua;" .. cwd .. "/?/init.lua;" .. package.path

local link_utils = require "link_utils"

local failures = {}

local function expect_equal(actual, expected, message)
  if actual ~= expected then
    table.insert(failures, string.format("%s\nexpected: %s\nactual: %s", message, vim.inspect(expected), vim.inspect(actual)))
  end
end

expect_equal(type(link_utils._extract_local_path_token), "function", "_extract_local_path_token should be exposed")
expect_equal(type(link_utils._extract_local_path_token_at_col), "function", "_extract_local_path_token_at_col should be exposed")
expect_equal(type(link_utils._resolve_local_path), "function", "_resolve_local_path should be exposed")
expect_equal(type(link_utils._local_path_to_uri), "function", "_local_path_to_uri should be exposed")

local temp_root = vim.fn.tempname()
vim.fn.mkdir(temp_root .. "/nested", "p")

local absolute_path = temp_root .. "/nested/file.txt"
local spaced_path = temp_root .. "/nested/file name #1.txt"
vim.fn.writefile({ "sample" }, absolute_path)
vim.fn.writefile({ "sample" }, spaced_path)

local original_cwd = vim.fn.getcwd()
vim.cmd.cd(temp_root)

local home_relative = "~/link-utils-local-path-test.txt"
local home_path = vim.fn.expand(home_relative)
vim.fn.writefile({ "home" }, home_path)

expect_equal(link_utils._extract_local_path_token("see ./nested/file.txt),"), "./nested/file.txt", "extracts relative path and trims punctuation")
expect_equal(link_utils._extract_local_path_token("open [../missing.txt]"), "../missing.txt", "extracts parent-relative path from brackets")
expect_equal(link_utils._extract_local_path_token("path: /tmp/example.txt,"), "/tmp/example.txt", "extracts absolute path and trims comma")
expect_equal(link_utils._extract_local_path_token("compare /tmp/first.txt then ./second.txt"), "/tmp/first.txt", "returns earliest explicit path token regardless of prefix priority")
expect_equal(link_utils._extract_local_path_token("notes mention docs/file.txt"), nil, "ignores paths without explicit prefix")
expect_equal(link_utils._extract_local_path_token("see ./nested/file.txt."), "./nested/file.txt", "trims trailing period from extracted path")
expect_equal(link_utils._extract_local_path_token("see ./nested/file.txt:"), "./nested/file.txt", "trims trailing colon from extracted path")
expect_equal(link_utils._extract_local_path_token("see `./nested/file.txt`"), "./nested/file.txt", "extracts local path inside backticks")

local markdown_line = "[./nested/file.txt](https://example.com)"
expect_equal(link_utils._extract_local_path_token_at_col(markdown_line, 4), "./nested/file.txt", "returns local path when cursor is on markdown label path")
expect_equal(link_utils._extract_local_path_token_at_col(markdown_line, 24), nil, "ignores label path when cursor is on markdown URL target")

local code_span_line = "`./nested/file.txt`"
expect_equal(link_utils._extract_local_path_token_at_col(code_span_line, 4), "./nested/file.txt", "returns local path when cursor is inside backticks")

expect_equal(link_utils._resolve_local_path("./nested/file.txt"), absolute_path, "resolves relative paths against cwd")
expect_equal(link_utils._resolve_local_path("./nested/file.txt."), absolute_path, "resolves relative paths with trailing period punctuation")
expect_equal(link_utils._resolve_local_path("./nested/file.txt:"), absolute_path, "resolves relative paths with trailing colon punctuation")
expect_equal(link_utils._resolve_local_path(home_relative), home_path, "expands home-relative paths")
expect_equal(link_utils._resolve_local_path("./nested/missing.txt"), nil, "returns nil for missing relative paths")

expect_equal(link_utils._local_path_to_uri("./nested/file.txt"), "file://" .. absolute_path, "builds file URI for existing local path")
expect_equal(link_utils._local_path_to_uri("./nested/file name #1.txt"), "file://" .. spaced_path:gsub(" ", "%%20"):gsub("#", "%%23"), "percent-encodes spaces and reserved characters in file URI")
expect_equal(link_utils._local_path_to_uri("./nested/missing.txt"), nil, "returns nil URI for missing local path")

vim.cmd.cd(original_cwd)
vim.fn.delete(temp_root, "rf")
vim.fn.delete(home_path)

if #failures > 0 then
  error(table.concat(failures, "\n\n"))
end
