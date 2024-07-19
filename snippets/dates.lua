local ls = require "luasnip"
local snippet = ls.snippet
local text_node = ls.text_node
-- get tomorrow date in a format of YYYY-MM-DD
local function get_tomorrow_date()
  local tomorrow = os.time() + 86400
  return os.date("%Y-%m-%d", tomorrow)
end

ls.add_snippets("all", {
  snippet("tomorrow", {
    ls.function_node(function() return get_tomorrow_date() end)
  }),
})
