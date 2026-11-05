# nvchad-config

Full Neovim config (NvChad v2.5 + Neovim 0.12). The repo root is the config root.

```sh
git clone git@github.com:jzyinq/nvchad-custom.git ~/.config/nvim
nvim   # lazy.nvim installs plugins on first start
```

Then inside nvim: `:MasonInstallAll` (LSP servers/formatters) and `:TSInstallAll`
(treesitter parsers; needs the `tree-sitter` CLI on PATH).

The `master` branch still holds the old NvChad v2.0 layout (only `lua/custom/`).
