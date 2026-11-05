local cwd = vim.fn.getcwd()
package.path = cwd .. "/?.lua;" .. cwd .. "/?/init.lua;" .. package.path

local captured

package.loaded.gx = {
  setup = function(opts)
    captured = opts
  end,
}

package.loaded["gx.helper"] = {
  find = function(line, mode, pattern, start_index)
    start_index = start_index or 1
    local i, j, value = string.find(line, pattern, start_index)
    if not i then
      return nil
    end

    if mode ~= "n" then
      return value
    end

    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    if i <= col and j >= col then
      return value
    end

    return nil
  end,
}

local failures = {}

local function expect_equal(actual, expected, message)
  if actual ~= expected then
    table.insert(failures, string.format("%s\nexpected: %s\nactual: %s", message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local plugins = dofile(cwd .. "/plugins.lua")
local gx_spec

for _, spec in ipairs(plugins) do
  if spec[1] == "chrishrb/gx.nvim" then
    gx_spec = spec
    break
  end
end

assert(gx_spec, "gx.nvim plugin spec not found")
gx_spec.config()

local url_handler = captured.handlers.url
expect_equal(type(url_handler), "table", "configures a custom url handler")

if url_handler then
  expect_equal(url_handler.handle("n", "~/Downloads/til.gif", {}), nil, "does not treat explicit home path as a web url")
  expect_equal(url_handler.handle("n", "example.com", {}), "https://example.com", "still treats plain domains as web urls")
end

if #failures > 0 then
  error(table.concat(failures, "\n\n"))
end
