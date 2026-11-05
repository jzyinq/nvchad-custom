require "nvchad.autocmds"

-- overdue-tasks indicator for Obsidian daily notes (registers autocmds)
require "custom.obsidian"

-- docs on hover for git config files (completion is wired up in plugins/init.lua)
require("custom.gitconfig").setup()
