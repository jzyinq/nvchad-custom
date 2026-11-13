local cwd = vim.fn.getcwd()
package.path = cwd .. "/?.lua;" .. cwd .. "/?/init.lua;" .. package.path

local link_utils = require "link_utils"

local failures = {}

local function expect_equal(actual, expected, message)
  if actual ~= expected then
    table.insert(failures, string.format("%s\nexpected: %s\nactual: %s", message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local extract = link_utils._extract_title

expect_equal(extract "<html><head><title>Hello World</title></head></html>", "Hello World", "reads <title>")
expect_equal(extract "<TITLE data-x='1'>\n  Hello\n  World \n</TITLE>", "Hello World", "collapses whitespace, ignores case and attributes")
expect_equal(
  extract '<title>Post | Site</title><meta property="og:title" content="Post">',
  "Post",
  "prefers og:title over <title>"
)
expect_equal(
  extract "<meta content='Post' property='og:title' /><title>Other</title>",
  "Post",
  "reads og:title with single quotes and content first"
)
expect_equal(extract '<meta property="og:title" content=""><title>Fallback</title>', "Fallback", "falls back to <title> when og:title is empty")
expect_equal(
  extract "<title>Tom &amp; Jerry &#8211; &quot;best&quot; &#x2014; &amp;lt;</title>",
  'Tom & Jerry – "best" — &lt;',
  "decodes HTML entities"
)
expect_equal(extract "<title>[RFC] a | b</title>", "\\[RFC\\] a \\| b", "escapes brackets and pipes")
expect_equal(
  extract "<title>x\\](https://evil.example) [y</title>",
  "x\\\\\\](https://evil.example) \\[y",
  "escapes backslashes so a title cannot close the link text"
)
expect_equal(extract "<title>a &lt;img src=x&gt; b</title>", "a \\<img src=x\\> b", "escapes angle brackets")
expect_equal(extract "<title>a\27[31mb\0c</title>", "a\\[31mbc", "drops control characters")
expect_equal(extract "<title>  </title>", nil, "returns nil for a blank title")
expect_equal(extract "<html><body>no title</body></html>", nil, "returns nil without a title")
expect_equal(extract(nil), nil, "returns nil for non-string input")

local long = extract("<title>" .. string.rep("ż", 200) .. "</title>")
expect_equal(vim.fn.strchars(long), 80, "caps long titles at 80 characters")
expect_equal(vim.fn.strcharpart(long, 79), "…", "marks a cut title with an ellipsis")

if #failures > 0 then
  error(table.concat(failures, "\n\n"))
end
