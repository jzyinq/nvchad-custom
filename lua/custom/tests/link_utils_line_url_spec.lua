local cwd = vim.fn.getcwd()
package.path = cwd .. "/?.lua;" .. cwd .. "/?/init.lua;" .. package.path

local link_utils = require "link_utils"

local failures = {}

local function expect_equal(actual, expected, message)
  if actual ~= expected then
    table.insert(failures, string.format("%s\nexpected: %s\nactual: %s", message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local function urls_of(line)
  local out = {}
  for _, item in ipairs(link_utils._urls_on_line(line)) do
    out[#out + 1] = (item.label or "-") .. "|" .. item.url
  end
  return table.concat(out, " ")
end

expect_equal(
  urls_of "    - Slide deck #1 [Talk, November 2026](https://slides.example.com/talk-2026-11/#slide=1&step=1) ",
  "Talk, November 2026|https://slides.example.com/talk-2026-11/#slide=1&step=1",
  "finds the url and label of a markdown link, without the closing paren"
)
expect_equal(urls_of "- [ ] check https://example.com/a?b=c today", "-|https://example.com/a?b=c", "finds a bare url")
expect_equal(urls_of "- one day hackathons - dev friday", "", "no url on the line")
expect_equal(
  urls_of "[a](https://example.com/a) and https://example.com/b",
  "a|https://example.com/a -|https://example.com/b",
  "lists several urls in line order"
)
expect_equal(
  urls_of "[https://example.com/a](https://example.com/a)",
  "-|https://example.com/a",
  "the same url twice counts as one"
)

-- open_link_on_line: stub gx and the opener, then check which path is taken
local opened, gx_opened, under_cursor
package.loaded.gx = {
  options = { handlers = { search = true, url = true }, handler_options = {} },
  open = function()
    gx_opened = true
  end,
}
package.loaded["gx.handler"] = {
  get_url = function(_, _, handlers)
    expect_equal(handlers.search, false, "search handler is off for the under-cursor check")
    return under_cursor
  end,
}
vim.ui.open = function(url)
  opened = url
end

local function run(line, matches)
  opened, gx_opened, under_cursor = nil, nil, matches
  vim.api.nvim_set_current_line(line)
  link_utils.open_link_on_line()
end

run("- deck [talk](https://example.com/talk)", {})
expect_equal(opened, "https://example.com/talk", "opens the only link when the cursor is on nothing")
expect_equal(gx_opened, nil, "does not also run gx")

run("- ARCH-123 [talk](https://example.com/talk)", { { name = "jira", url = "https://jira/ARCH-123" } })
expect_equal(opened, nil, "leaves it to gx when the cursor is on something")
expect_equal(gx_opened, true, "runs gx when the cursor is on something")

local typed
vim.fn.getcharstr = function()
  return typed
end

typed = "2"
run("- [a](https://example.com/a) [b](https://example.com/b)", {})
expect_equal(opened, "https://example.com/b", "opens the link whose number is typed")
expect_equal(gx_opened, nil, "does not run gx after picking")

typed = "\27"
run("- [a](https://example.com/a) [b](https://example.com/b)", {})
expect_equal(opened, nil, "any other key cancels")
expect_equal(gx_opened, nil, "cancelling does not run gx")

typed = "3"
run("- [a](https://example.com/a) [b](https://example.com/b)", {})
expect_equal(opened, nil, "a number past the list opens nothing")

run("- plain words", {})
expect_equal(gx_opened, true, "falls back to gx (web search) when the line has no link")

expect_equal(package.loaded.gx.options.handlers.search, true, "gx's own options are left untouched")

if #failures > 0 then
  error(table.concat(failures, "\n\n"))
end
print "ok"
