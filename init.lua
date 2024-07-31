-- vim.o.foldcolumn = "1" -- '0' is not bad
-- vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
-- vim.o.foldlevelstart = 99
-- vim.o.foldenable = true
local vim = vim
local opt = vim.opt
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldlevel = 99
opt.foldenable = false

local autocmd = vim.api.nvim_create_autocmd
autocmd("DirChanged", {
  callback = function()
    local venv_dir_names = { "venv", ".venv" }
    for _, dir_name in ipairs(venv_dir_names) do
      local venv = vim.fn.finddir(dir_name, vim.fn.getcwd() .. ";")
      if venv ~= "" then
        require("venv-selector").retrieve_from_cache()
      end
    end
  end,
})

opt.relativenumber = true

-- autocmd("BufEnter", {
--   callback = function()
--     require "async"(function()
--       local bufnr = vim.api.nvim_get_current_buf()
--       -- make sure buffer is attached
--       require("ufo").attach(bufnr)
--       -- getFolds return Promise if providerName == 'lsp'
--       local ranges = await(require("ufo").getFolds(bufnr, providerName))
--       local ok = require("ufo").applyFolds(bufnr, ranges)
--       if ok then
--         require("ufo").closeAllFolds()
--       end
--     end)
--   end,
-- })
