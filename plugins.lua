local overrides = require "custom.configs.overrides"

---@type NvPluginSpec[]
local plugins = {

  -- Override plugin definition options
  {
    "hrsh7th/nvim-cmp",
    opts = {

      sources = {
        { name = "copilot", group_index = 2 },
        { name = "emoji" },
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "buffer" },
        { name = "nvim_lua" },
        { name = "path" },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- defaults
        "vim",
        "lua",

        -- web dev
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "python",
        "go",
        "markdown",
        "yaml",
      },
    },
  },
  {
    "NvChad/nvterm",
    opts = {
      terminals = {
        type_opts = {
          float = {
            row = 0.1,
            col = 0.05,
            width = 0.9,
            height = 0.8,
          },
        },
      },
      behavior = {
        auto_close_on_quit = {
          enabled = true,
        },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- format & linting
      {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          require "custom.configs.null-ls"
        end,
      },
    },
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },

  -- override plugin configs
  {
    "williamboman/mason.nvim",
    opts = overrides.mason,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
  },

  -- Install a plugin
  {
    "nvim-telescope/telescope-project.nvim",
    dependencies = { "telescope.nvim" },
    config = function()
      require("telescope").load_extension "project"
    end,
  },
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
    config = function()
      require("venv-selector").setup { name = { "venv", ".venv" }, auto_refresh = true }
    end,
    event = "VeryLazy", -- Optional: needed only if you want to type `:VenvSelect` without a keymapping
  },
  {

    "ruifm/gitlinker.nvim",
    event = "BufRead",
    config = function()
      require("gitlinker").setup {
        opts = {
          -- remote = 'github', -- force the use of a specific remote
          -- adds current line nr in the url for normal mode
          add_current_line_on_normal_mode = true,
          -- callback for what to do with the url/
          action_callback = require("gitlinker.actions").open_in_browser,
          -- print the url after performing the action
          print_url = false,
          -- mapping to call url generation
          mappings = "<leader>gy",
        },
      }
    end,
    dependencies = "nvim-lua/plenary.nvim",
  },
  { "kevinhwang91/nvim-bqf", event = "VeryLazy" },
  {
    "SmiteshP/nvim-navbuddy",
    dependencies = {
      "neovim/nvim-lspconfig",
      "SmiteshP/nvim-navic",
      "MunifTanjim/nui.nvim",
      "numToStr/Comment.nvim",         -- Optional
      "nvim-telescope/telescope.nvim", -- Optional
    },
    config = function()
      require("nvim-navbuddy").setup { window = { size = "90%" }, lsp = { auto_attach = true } }
    end,
  },
  {
    "glepnir/dashboard-nvim",
    event = "VimEnter",
    config = function()
      require("dashboard").setup {}
    end,
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
  },
  -- To make a plugin not be loaded
  -- {
  --   "NvChad/nvim-colorizer.lua",
  --   enabled = false
  -- },

  -- All NvChad plugins are lazy-loaded by default
  -- For a plugin to be loaded, you will need to set either `ft`, `cmd`, `keys`, `event`, or set `lazy = false`
  -- If you want a plugin to load on startup, add `lazy = false` to a plugin spec, for example
  -- {
  --   "mg979/vim-visual-multi",
  --   lazy = false,
  -- }
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function()
      require("lsp_signature").setup {
        bind = true, -- This is mandatory, otherwise border config won't get registered.
        handler_opts = {
          border = "rounded",
        },
      }
    end,
  },
  {
    "ranelpadon/python-copy-reference.vim",
    event = "BufRead",
  },
  {

    "Pocco81/auto-save.nvim",
    config = function()
      require("auto-save").setup {
        execution_message = {
          message = function() -- message to print on save
            return ("AutoSave: saved at " .. vim.fn.strftime "%H:%M:%S")
          end,
          dim = 0.18,               -- dim the color of `message`
          cleaning_interval = 1250, -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
        },
      }
    end,
  },
  {
    "anuvyklack/fold-preview.nvim",
    dependencies = "anuvyklack/keymap-amend.nvim",
    config = function()
      require("fold-preview").setup {
        -- Your configuration goes here.
      }
    end,
    event = "BufRead",
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    event = "BufRead",
  },
  {
    "zbirenbaum/copilot-cmp",
    event = "InsertEnter",
    dependencies = { "zbirenbaum/copilot.lua" },
    config = function()
      vim.defer_fn(function()
        require("copilot").setup()     -- https://github.com/zbirenbaum/copilot.lua/blob/master/README.md#setup-and-configuration
        require("copilot_cmp").setup() -- https://github.com/zbirenbaum/copilot-cmp/blob/master/README.md#configuration
      end, 100)
    end,
  },
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" },  -- for curl, log wrapper
    },
    opts = {
      debug = true, -- Enable debugging
      -- See Configuration section for rest
    },
    config = function()
      require("CopilotChat").setup {}
    end,
    -- assign gcc hotkey to toggle chat
    keys = {
      { "<leader>cp", "<cmd>lua require('CopilotChat').toggle()<cr>", "toggle copilot chat" },
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
  {
    "chrishrb/gx.nvim",
    keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
    cmd = { "Browse" },
    init = function()
      vim.g.netrw_nogx = 1 -- disable netrw gx
    end,
    dependencies = { "nvim-lua/plenary.nvim" },
    submodules = false, -- not needed, submodules are required only for tests

    -- you can specify also another config if you want
    config = function()
      require("gx").setup {
        open_browser_app = "xdg-open", -- specify your browser app; default for macOS is "open", Linux "xdg-open" and Windows "powershell.exe"
        handlers = {
          plugin = true,               -- open plugin links in lua (e.g. packer, lazy, ..)
          github = true,               -- open github issues
          package_json = true,         -- open dependencies from package.json
          search = true,               -- search the web/selection on the web if nothing else is found
          go = true,                   -- open pkg.go.dev from an import statement (uses treesitter)
          jira = {                     -- custom handler to open Jira tickets (these have higher precedence than builtin handlers)
            name = "jira",             -- set name of handler
            handle = function(mode, line, _)
              local ticket = require("gx.helper").find(line, mode, "(%u+-%d+)")
              if ticket and #ticket < 20 then
                return "https://piwikpro.atlassian.net/browse/" .. ticket
              end
            end,
          },
        },
        handler_options = {
          search_engine = "google",               -- you can select between google, bing, duckduckgo, and ecosia
          select_for_search = false,              -- if your cursor is e.g. on a link, the pattern for the link AND for the word will always match. This disables this behaviour for default so that the link is opened without the select option for the word AND link

          git_remotes = { "upstream", "origin" }, -- list of git remotes to search for git issue linking, in priority
          git_remote_push = false,                -- use the push url for git issue linking,
        },
      }
    end,
  },
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup {
        surrounds = {
          ["l"] = {
            add = function()
              local clipboard = vim.fn.getreg("+"):gsub("\n", "")
              return {
                { "[" },
                { "](" .. clipboard .. ")" },
              }
            end,
            find = "%b[]%b()",
            delete = "^(%[)().-(%]%b())()$",
            change = {
              target = "^()()%b[]%((.-)()%)$",
              replacement = function()
                local clipboard = vim.fn.getreg("+"):gsub("\n", "")
                return {
                  { "" },
                  { clipboard },
                }
              end,
            },
          },
        },
        -- Configuration here, or leave empty to use defaults
      }
    end,
  },
  {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    -- ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    event = {
      -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
      -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
      "BufReadPre /home/jzy/homecloud/backups/obsidian/piwik/**.md",
      "BufNewFile /home/jzy/homecloud/backups/obsidian/piwik/**.md",
    },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",

      -- see below for full list of optional dependencies 👇
    },
    opts = {
      workspaces = {
        {
          name = "piwik",
          path = "/home/jzy/homecloud/backups/obsidian/piwik",
        },
      },

      -- see below for full list of options 👇
    },
  },
}

return plugins

--
-- -- function for adding two integers
