---
name: verify-config
description: Use after changing this Neovim config (plugins, keymaps, chadrc, options, LSP, treesitter) or after updating plugins/Neovim, to confirm nvim still starts cleanly with LSP and syntax highlighting working, and to compare keymaps/plugins before and after a change.
---

# Verify the nvim config

Run checks against a **real UI**, not plain `nvim --headless`: NvChad v2.5 loads LSP, gitsigns,
etc. on `User FilePost`, which fires only after `UIEnter`. The scripts start nvim inside `tmux`
and dump state from a deferred Lua function.

## Smoke test

From the config root:

```sh
.claude/skills/verify-config/scripts/verify.sh FILE...
```

Pick files that exercise what changed. Defaults worth using:
- a daily note from the Obsidian vault, e.g. `~/homecloud/backups/obsidian/piwik/daily/<today>.md`
  (markdown + YAML frontmatter injection, obsidian.nvim, marksman)
- a small `.py`, `.yaml`, `.lua` or `.css` file in a temp dir for the language you touched

Each report shows filetype, attached LSP clients, treesitter captures per language, loaded plugin
count and `:messages`. The script exits 1 if any report has a `FAIL` line:
- `treesitter active but no highlight captures`: highlight queries are missing. A highlighter
  counts as "active" even then, so never treat `active` alone as proof that highlighting works.
- `no highlights query for <lang>`
- errors in `:messages`

Options: `-a NVIM_APPNAME` (test another config, e.g. `nvim.old`), `-n /path/to/nvim`,
`-w MS` (wait before dumping; default 6000, raise it on first start after plugin installs).

Known noise, not a failure: `errmsg: E31: No such mapping` on markdown buffers, and `W325`
swapfile warnings when the file is open in another nvim.

## Keymap / plugin diff

To prove a change didn't drop keymaps or stop plugins loading, dump before and after and diff:

```sh
out=$(mktemp); tmux new-session -d -s kd -x 200 -y 50 \
  "BOOT_OUT=$out nvim -c 'luafile $PWD/.claude/skills/verify-config/scripts/keymap_dump.lua' FILE"
# wait until $out exists, then: tmux kill-session -t kd
```

Lines are `G|B <mode> <lhs>  -- <desc>` (global / buffer-local) and `P <plugin> loaded|lazy`.
Compare dumps with `comm`/`diff`; strip the `-- desc` part first if only presence matters.

## If treesitter highlighting is broken

nvim-treesitter (`main` branch) links `~/.local/share/nvim/site/queries/<lang>` to absolute
paths. Look for dangling or stale links (`find ~/.local/share/nvim/site/queries -xtype l`) and
re-point them, or reinstall parsers with `:TSInstallAll` (needs the `tree-sitter` CLI).
