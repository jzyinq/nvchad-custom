# nvchad-config

Full Neovim config (NvChad v2.5 + Neovim 0.12). The repo root is the config root.

```sh
git clone git@github.com:jzyinq/nvchad-custom.git ~/.config/nvim
nvim   # lazy.nvim installs plugins on first start
```

Then inside nvim: `:MasonInstallAll` (LSP servers/formatters) and `:TSInstallAll`
(treesitter parsers; needs the `tree-sitter` CLI on PATH).

The migration from the old NvChad v2.0 layout (where only `lua/custom/` was tracked) is commit
`e020762`; its step-by-step history is on the `nvchad25` branch.
