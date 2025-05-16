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
    ["<leader>tf"] = {
      function()
        require("custom.obsidian").search_incomplete_tasks()
      end,
      "Tasks filter",
    },
    ["<leader>th"] = {
      ":lua require('telescope.builtin').command_history()<CR>",
      "Command History",
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

local task_mappings = {
  ["<leader>td"] = {
    function()
      require("custom.obsidian").toggle_checkbox "x"
    end,
    "Todo Create",
    mode = { "n", "v" },
  },
  ["<leader>ta"] = {
    function()
      require("custom.obsidian").toggle_checkbox "-"
    end,
    "Todo Abandoned",
    mode = { "n", "v" },
  },
  ["<leader>tq"] = {
    function()
      require("custom.obsidian").toggle_checkbox "?"
    end,
    "Todo Question",
    mode = { "n", "v" },
  },
  ["<leader>ti"] = {
    function()
      require("custom.obsidian").toggle_checkbox ">"
    end,
    "Todo Abandoned",
    mode = { "n", "v" },
  },
  ["<leader>tw"] = {
    function()
      require("custom.obsidian").toggle_checkbox "!"
    end,
    "Todo toggle",
    mode = { "n", "v" },
  },
  ["<leader>tt"] = {
    function()
      require("custom.obsidian").toggle_checkbox " "
    end,
    "Todo toggle",
    mode = { "n", "v" },
  },
  ["<leader>tr"] = {
    function()
      require("custom.obsidian").toggle_checkbox()
    end,
    "Todo toggle",
    mode = { "n", "v" },
  },
  ["<leader>go"] = {
    "<cmd>:ObsidianOpen<cr>",
    "Open note in Obsidian",
    mode = { "n", "v" },
  },
}

M.obsidian = {
  n = task_mappings,
  v = task_mappings,
}

return M
