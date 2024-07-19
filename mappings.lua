---@type MappingsTable
local M = {}

M.disabled = {
  n = {
    ["<leader>v"] = "",
    ["<leader>ls"] = "",
  },
}
M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
  },
  i = {
    ["<S-Tab>"] = { "<C-d>", "Unindent line" },
  },
}
M.navbuddy = {
  n = {
    ["<leader>ln"] = { ":lua require('nvim-navbuddy').open()<CR>", "LSP navigation" },
  },
}

-- more keybinds!
M.telescope_project = {
  n = {
    ["<leader>fp"] = {
      ":lua require'telescope'.extensions.project.project{display_type = 'full'}<CR>",
      "Select project",
    },
  },
}

M.venv_select = {
  n = {
    ["<leader>vs"] = { "<cmd>:VenvSelect<cr>", "Select python venv" },
    ["<leader>vc"] = { "<cmd>:VenvSelectCached<cr>", "Select cached python venv" },
  },
}

M.git = {
  n = {
    ["<leader>gg"] = { "<cmd>:LazyGit<cr>", "Lazy git" },
  },
}

M.lspconfig = {
  n = {
    ["<leader>lg"] = {
      function()
        vim.lsp.buf.signature_help()
      end,
      "LSP signature help",
    },
  },
}

M.python_reference = {
  n = {
    ["<leader>rd"] = { "<cmd>:PythonCopyReferenceDotted<cr>", "Python dotted reference" },
    ["<leader>rp"] = { "<cmd>:PythonCopyReferencePytest<cr>", "Python pytest reference" },
    ["<leader>ri"] = { "<cmd>:PythonCopyReferenceImport<cr>", "Python import reference" },
  },
}

-- vim.keymap.set({"n", "v"}, "<leader>nd", function() M.toggle_checkbox("x") end, { desc="Todo done", noremap = true })
M.obsidian = {
  n = {
    ["<leader>td"] = {
      function()
        require('custom.obsidian').toggle_checkbox "x"
      end,
      "Todo Create",
    },
    ["<leader>tc"] = {
      function()
        require('custom.obsidian').toggle_checkbox "-"
      end,
      "Todo Abandoned",
    },
    ["<leader>tt"] = {
      function()
        require('custom.obsidian').toggle_checkbox " "
      end,
      "Todo toggle",
    },
    ["<leader>tr"] = {
      function()
        require('custom.obsidian').toggle_checkbox()
      end,
      "Todo toggle",
    },
  },
}

return M
