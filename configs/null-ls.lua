local null_ls = require "null-ls"

local b = null_ls.builtins
local line_length = 120
local sources = {
  -- general
  -- change json formatting indent to 2 lines instead of four (default)
  b.formatting.clang_format.with { extra_args = { "-s", "2" } },
  -- webdev stuff
  b.formatting.deno_fmt.with {
    extra_args = { "--line-width", tostring(line_length), "--indent-width", 2 },
  }, -- choosed deno for ts/js files cuz its very fast!
  b.formatting.prettier.with {
    filetypes = { "html", "markdown", "css" },
    extra_args = { "--print-width", tostring(line_length), "--tab-width", 2 },
  }, -- so prettier works only on these filetypes

  -- Lua
  b.formatting.stylua,

  -- JavaScript
  b.formatting.prettier.with { extra_args = { "--print-width", tostring(line_length), "--tab-width", 2 } },

  -- XML
  b.formatting.xmlformat,

  -- Golang
  b.formatting.djlint,
  b.formatting.gofumpt,
  b.formatting.goimports,
  b.formatting.golines.with { extra_args = { "--max-len", line_length } },
  b.code_actions.gomodifytags,

  -- Python
  b.formatting.black.with { extra_args = { "--line-length", line_length } },
}

null_ls.setup {
  debug = true,
  sources = sources,
}
