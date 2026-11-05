# CLAUDE.md

Neovim config built on NvChad v2.5, running on Neovim 0.12+. The git repo is the
config root (remote `git@github.com:jzyinq/nvchad-custom.git`).

## Layout

NvChad itself is a lazy.nvim plugin (`NvChad/NvChad`, branch `v2.5`); its code lives in
`~/.local/share/<appname>/lazy/NvChad` and `.../lazy/ui` and must never be edited.
Everything in this repo is ours:

- `init.lua` - bootstraps lazy.nvim, loads NvChad + `lua/plugins`, then options/autocmds/mappings
- `lua/chadrc.lua` - NvChad settings (schema: `nvconfig.lua` in NvChad/ui v3.0): theme, statusline
  (writer-mode module), nvdash, floating term size, `M.mason.pkgs` for `:MasonInstallAll`
- `lua/options.lua` / `lua/autocmds.lua` / `lua/mappings.lua` - load NvChad defaults first, then ours
- `lua/plugins/init.lua` - plugin specs; specs for NvChad's own plugins are merged with its specs
  (note: lists in `opts` replace NvChad's lists, they are not extended)
- `lua/configs/lazy.lua` - lazy.nvim options
- `lua/custom/` - own modules, required as `custom.*`:
  - `init.lua` - options, autocmds, filetype rules (loaded from `lua/options.lua`)
  - `mappings.lua` - keymaps as v2.0-style tables, turned into `vim.keymap.set` by `lua/mappings.lua`
    (`M.disabled` removes NvChad defaults)
  - `configs/` - `lspconfig.lua` (servers via `vim.lsp.enable`), `null-ls.lua` (formatters), `overrides.lua`
    (treesitter parser list, nvim-tree)
  - `obsidian.lua`, `link_utils.lua`, `gitconfig.lua`, `diffview.lua`, `zsh_history.lua`,
    `emoji_picker.lua`, `writer_mode.lua`, `highlights.lua`, `snippets/`, `tests/`
- `after/ftplugin/`, `spell/` - filetype tweaks and the spell dictionary

## Guidelines

- Put customizations in this repo only; never edit NvChad's files under `~/.local/share`.
- Keymaps go in `lua/custom/mappings.lua`; plugin keymaps can also use lazy `keys`.
- `<leader>rr` runs `:restart` (reloads the whole config, restores the session).
- Verify changes with a real UI, not plain `--headless`: NvChad loads LSP, gitsigns, etc. on the
  `User FilePost` event, which only fires after `UIEnter`. Running nvim inside `tmux` and dumping
  state from a deferred Lua function works.
- `luac` may be unavailable; load files with `nvim --headless` for syntax checks.
- Treesitter is the `main` branch of nvim-treesitter: parsers are compiled with the `tree-sitter`
  CLI (`~/.local/bin/tree-sitter`), highlighting starts via NvChad's FileType autocmd, and folding
  uses `vim.treesitter.foldexpr()`.
