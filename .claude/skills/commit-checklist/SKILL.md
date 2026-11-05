---
name: commit-checklist
description: Use before every commit in this Neovim config repo (whenever about to run git commit, asked to "commit", "save this", "push", or finishing a change). Makes sure CLAUDE.md and README.md still match the code, so the repo's knowledge base stays current, and that the change was verified.
---

# Before committing to the nvim config

`CLAUDE.md` is the knowledge base for this repo (`AGENTS.md` links to it). An outdated
CLAUDE.md is worse than none: it confidently sends the next session the wrong way. Treat
updating it as part of the change, not a follow-up.

## 1. Review the change
`git status` and `git diff` (plus `git diff --cached`). Know exactly what the commit contains.

## 2. Check CLAUDE.md and README.md against the diff
Read both and look for anything the change makes wrong or incomplete:
- **Layout**: files added, moved, renamed or removed (CLAUDE.md lists them under "Layout").
- **Conventions**: where keymaps, plugin specs, options or settings live and how they load.
- **Behaviour worth knowing**: new or changed keymaps people rely on (e.g. `<leader>rr`),
  plugins added/removed, options in `lua/chadrc.lua` that change defaults.
- **Hard-won lessons**: if this change came from debugging something non-obvious (a trap,
  a gotcha, a verification trick), add it under "Guidelines" so it isn't relearned.
- **Stale statements**: references to things this change removes or replaces.

Update the docs in the same commit as the code. If nothing needs changing, say so explicitly
when reporting the commit ("CLAUDE.md still accurate"), so it's clear the check happened.

Keep CLAUDE.md about what isn't obvious from the code; don't paste code or list every keymap.

## 3. Verify
If the change affects runtime behaviour, run the `verify-config` skill on relevant files first.
Report what was verified; if something wasn't, say so.

## 4. Commit
- Commits are GPG-signed with a key on a YubiKey. If signing fails with a pinentry timeout or
  `Card error`, stop and ask the user to unlock it (`! echo test | gpg --clearsign > /dev/null`),
  then retry. Never commit with `--no-gpg-sign` unless the user says so.
- One logical change per commit; message says what and why.
- Push only when the user asks. The repo is **public**: never commit secrets, work-internal
  material (e.g. Piwik PRO tooling) or local settings (`.claude/settings.local.json`).
