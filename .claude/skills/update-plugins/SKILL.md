---
name: update-plugins
description: Use when updating Neovim plugins, NvChad, Mason packages or treesitter parsers in this config (e.g. "update plugins", "bump NvChad", "Lazy update"), including reviewing and committing lazy-lock.json.
---

# Update plugins, NvChad, Mason and parsers

`lazy-lock.json` is tracked, so every update is a reviewable, revertable diff.

1. Start from a clean tree: `git status` shows nothing to commit.
2. Update plugins (NvChad itself is the `NvChad` plugin, its UI is `ui`/`base46`):
   ```sh
   nvim --headless "+Lazy! update" +qa
   ```
   For a single plugin: `"+Lazy! update <name>"`.
3. Parsers and Mason packages, if wanted:
   ```sh
   nvim --headless "+TSUpdate" +qa      # needs the tree-sitter CLI (~/.local/bin/tree-sitter)
   ```
   Mason updates are interactive (`:Mason`, then `U`); `:MasonInstallAll` installs anything listed
   in `lua/chadrc.lua` (`M.mason.pkgs`) that is missing.
4. Review `git diff lazy-lock.json`. For NvChad/ui bumps, skim upstream commits for breaking
   changes (`gh api 'repos/NvChad/NvChad/commits?sha=v2.5&per_page=10'`, same for `NvChad/ui`
   on `v3.0`), especially changes to `nvconfig.lua` options used in `lua/chadrc.lua`.
5. Run the `verify-config` skill on a daily note plus a file for each language you rely on.
   Also do a keymap diff if NvChad's own mappings may have changed.
6. If something broke: `git checkout lazy-lock.json` and `nvim --headless "+Lazy! restore" +qa`
   brings every plugin back to the locked commits.
7. Commit via the `commit-checklist` skill. Message: which plugins moved and anything notable.
