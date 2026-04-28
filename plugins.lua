local overrides = require "custom.configs.overrides"

---@type NvPluginSpec[]
local plugins = {

  -- Override plugin definition options
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-cmdline",
    },
    opts = {
      sources = {
        { name = "emoji" },
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "buffer" },
        { name = "nvim_lua" },
        { name = "path" },
        per_filetype = {
          codecompanion = { "codecompanion" },
        },
      },
    },
    config = function(_, opts)
      local cmp = require "cmp"
      cmp.setup(opts)

      -- `/` search completion
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      -- `:` command completion
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end,
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
        "nvimtools/none-ls.nvim",
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
    branch = "main",
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
          mappings = "<leader>gb",
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
      "numToStr/Comment.nvim", -- Optional
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
  -- Override colorizer to use new structured options format
  {
    "NvChad/nvim-colorizer.lua",
    opts = {
      options = {
        parsers = {
          names = { enable = true },
          hex = { default = true },
          rgb = { enable = false },
          hsl = { enable = false },
        },
        display = {
          mode = "background",
        },
      },
    },
  },

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
          dim = 0.18, -- dim the color of `message`
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
      local gx_helper = require "gx.helper"
      local link_utils = require "custom.link_utils"

      local function is_explicit_local_path(token)
        return token
          and (token:match "^~/" or token:match "^%./" or token:match "^%.%./" or token:match "^/")
      end

      require("gx").setup {
        open_browser_app = "xdg-open", -- specify your browser app; default for macOS is "open", Linux "xdg-open" and Windows "powershell.exe"
        handlers = {
          plugin = true, -- open plugin links in lua (e.g. packer, lazy, ..)
          github = true, -- open github issues
          package_json = true, -- open dependencies from package.json
          url = {
            name = "url",
            handle = function(mode, line, _)
              local url = gx_helper.find(line, mode, "(https?://[a-zA-Z%d_/%%%-%.~@\\+#=?&:*]+)")
              if url then
                return url:gsub("\\([%%p])", "%1")
              end

              local raw = gx_helper.find(line, mode, "([a-zA-Z%d_/%-%.~@\\+#]+%.[a-zA-Z_/%%%-%.~@\\+#=?&:]+)")
              if not raw or is_explicit_local_path(raw) then
                return nil
              end

              return ("https://" .. raw):gsub("\\([%%p])", "%1")
            end,
          },
          go = true, -- open pkg.go.dev from an import statement (uses treesitter)
          jira = { -- custom handler to open Jira tickets (these have higher precedence than builtin handlers)
            name = "jira", -- set name of handler
            handle = function(mode, line, _)
              local ticket = require("gx.helper").find(line, mode, "(%u+-%d+)")
              if ticket and #ticket < 20 then
                return "https://piwikpro.atlassian.net/browse/" .. ticket
              end
            end,
          },
          local_path = {
            name = "local_path",
            handle = function(mode, line, _)
              local path
              if mode == "n" then
                local col = vim.api.nvim_win_get_cursor(0)[2] + 1
                path = link_utils._extract_local_path_token_at_col(line, col)
              else
                local token = gx_helper.find(line, mode, "([^%s]+)")
                if token then
                  path = link_utils._extract_local_path_token(token)
                end
              end

              if not path then
                return nil
              end

              return link_utils._local_path_to_uri(path)
            end,
          },
          search = true, -- search the web/selection on the web if nothing else is found
        },
        handler_options = {
          search_engine = "google", -- you can select between google, bing, duckduckgo, and ecosia
          select_for_search = false, -- if your cursor is e.g. on a link, the pattern for the link AND for the word will always match. This disables this behaviour for default so that the link is opened without the select option for the word AND link

          git_remotes = { "upstream", "origin" }, -- list of git remotes to search for git issue linking, in priority
          git_remote_push = false, -- use the push url for git issue linking,
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
          ["`"] = {
            add = function()
              local mode = vim.fn.visualmode()
              if mode == "V" then
                return { { "```" }, { "```" } }
              else
                return { { "`" }, { "`" } }
              end
            end,
            find = "```.-```",
            delete = "^(```)().-(```)()$",
          },
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
    "obsidian-nvim/obsidian.nvim",
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

      legacy_commands = false,
      daily_notes = {
        -- Optional, if you keep daily notes in a separate directory.
        folder = "daily",
        -- Optional, if you want `Obsidian yesterday` to return the last work day or `Obsidian tomorrow` to return the next work day.
        workdays_only = true,
      },
      workspaces = {
        {
          name = "piwik",
          path = "/home/jzy/homecloud/backups/obsidian/piwik",
        },
      },

      -- -- Optional, by default when you use `:ObsidianFollowLink` on a link to an external
      -- -- URL it will be ignored but you can customize this behavior here.
      -- ---@param url string
      -- follow_url_func = function(url)
      --   -- Open the URL in the default web browser.
      --   vim.fn.jobstart { "xdg-open", url } -- linux
      -- end,
      -- -- see below for full list of options 👇
    },
  },
  {
    "Almo7aya/openingh.nvim",
    lazy = true,
    -- assign gcc hotkey to toggle chat
    keys = {
      { "gh", ":OpenInGHFile <CR>", mode = { "n" } },
      { "gh", ":OpenInGHFileLines <CR>", mode = { "v" } },
    },
  },
  {
    "m4xshen/hardtime.nvim",
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      disabled_keys = {
        ["<Up>"] = false, -- Allow <Up> key
        ["<Down>"] = false,
        ["<Left>"] = false, -- Allow <Left> key
        ["<Right>"] = false, -- Allow <Right> key
      },
    },
  },
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      terminal_cmd = "~/.local/bin/claude", -- Point to local installation
      terminal = {
        split_width_percentage = 0.5,
      },
    },
    config = true,
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
      },
      -- Diff management
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },
  -- {
  --   "olimorris/codecompanion.nvim",
  --   version = "^19.0.0",
  --   cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionChat", "CodeCompanionCmd" },
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-treesitter/nvim-treesitter",
  --     "ravitemer/mcphub.nvim",
  --   },
  --   opts = {
  --     adapters = {
  --       acp = {
  --         claude_code = function()
  --           return require("codecompanion.adapters").extend("claude_code", {
  --             env = {
  --               CLAUDE_CODE_OAUTH_TOKEN = "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",
  --             },
  --           })
  --         end,
  --       },
  --     },
  --     teractions = {
  --       chat = {
  --         adapter = "claude_code",
  --         model = "claude-sonnet-4-6",
  --       },
  --     },
  --     opts = {
  --       log_level = "DEBUG",
  --     },
  --   },
  },
  {
  -- },
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
      require("notify").setup()
      vim.notify = require "notify"
    end,
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      highlight = {
        pattern = [[.*<(KEYWORDS)\s*]], -- pattern or table of patterns, used for highlighting (vim regex)
      },
    },
  },
}

return plugins

--
-- -- function for adding two integers
