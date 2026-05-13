# writer mode word count design

## Summary

Extend the existing `<leader>W` writer mode so it also shows a statusline word counter in the format `current/750`, visible only while writer mode is enabled.

The counter should reuse Neovim's built-in word counting via `vim.fn.wordcount()` and turn green once the count reaches or exceeds `750`.

## Goals

- Keep the existing `<leader>W` workflow as the entry point for writer mode.
- Show a live `X/750` counter only while writer mode is enabled.
- Reuse Neovim's built-in word count data instead of implementing custom counting logic.
- Integrate with the existing NvChad statusline without replacing the whole statusline implementation.
- Make the counter visually switch to green at `>= 750` words.

## Non-goals

- Changing writer mode behavior beyond what is required for the counter.
- Replacing NvChad's statusline theme or layout.
- Showing the counter outside writer mode.
- Adding a new plugin for writing mode or statusline rendering.

## Chosen approach

Add a small custom statusline module under `lua/custom/` and inject it through NvChad's `ui.statusline.overriden_modules` hook.

The module will:

- Return an empty string unless `vim.g.writer_mode` is enabled.
- Read the current word count from `vim.fn.wordcount().words`.
- Format the display as ` <count>/750 `.
- Use one highlight group below the threshold and a green highlight group at `>= 750`.
- Be inserted into the right-hand side of the existing statusline so the rest of the NvChad layout remains intact.

The existing `<leader>W` mapping will also trigger `redrawstatus()` after toggling writer mode so the counter appears or disappears immediately.

## Alternatives considered

### Compute words manually from buffer text

This would work, but it duplicates built-in Neovim functionality and creates more edge cases around what counts as a word.

### Replace the entire statusline with a custom one

This would give full control over placement and styling, but it is a much larger change than needed and increases maintenance cost.

### Show the counter in winbar or notifications

This would avoid statusline integration, but it is less consistent with the existing UI and less useful as a persistent progress indicator.

## Implementation details

### Location

Keep all changes inside `lua/custom/`:

- `lua/custom/mappings.lua` for the writer mode toggle refresh
- `lua/custom/chadrc.lua` for the `overriden_modules` hook
- `lua/custom/highlights.lua` for the counter highlight groups
- a new helper module such as `lua/custom/writer_mode.lua` for statusline-specific logic

### Statusline integration

Use `M.ui.statusline.overriden_modules` in `chadrc.lua` to modify the default module list that NvChad builds.

The override function should insert the writer mode counter module into the existing `modules` array near the right-hand informational segments, without replacing unrelated entries.

### Counter logic

Use `vim.fn.wordcount()` as the single source of truth.

The module should:

- read `wordcount().words`
- default safely to `0` if the return value is missing
- compare the value to the fixed threshold `750`
- return a statusline-formatted string with the appropriate highlight group

### Highlighting

Add two custom highlight groups:

- a default writer mode counter highlight that fits the current statusline palette
- a success highlight that turns the counter green once the threshold is met

The green state should change only color, not layout or text format.

### Refresh behavior

After toggling writer mode with `<leader>W`, call `vim.cmd.redrawstatus()` so the statusline updates immediately.

Normal Neovim redraws while editing should keep the count current without any separate timer or autocommand unless verification shows a refresh gap.

## Data flow

1. User presses `<leader>W`.
2. The mapping toggles `vim.g.writer_mode`, updates existing writer mode settings, and redraws the statusline.
3. NvChad rebuilds the statusline.
4. The custom override injects the writer mode counter segment into the module list.
5. The counter module checks whether writer mode is active.
6. If active, it reads `vim.fn.wordcount().words`, formats `X/750`, and selects the highlight based on the threshold.
7. If inactive, it returns an empty string so nothing is shown.

## Error handling

- If `vim.fn.wordcount()` does not return a numeric `words` field, fall back to `0`.
- If the statusline override runs in a buffer where writer mode should not display anything, return an empty segment rather than raising an error.
- If placement in the module list needs adjustment after testing, prefer changing only the insertion index rather than restructuring the statusline.

## Testing

Verify these cases manually in Neovim:

- `<leader>W` enables writer mode and shows the counter immediately.
- `<leader>W` disables writer mode and hides the counter immediately.
- editing text updates the counter while writer mode is active.
- the counter stays non-green below `750` words.
- the counter turns green at exactly `750` words.
- the counter remains green above `750` words.
- non-writer-mode buffers do not show the counter.

## Risks and mitigations

- The chosen insertion point may look awkward in the current statusline layout.
  Mitigation: use the existing module array and adjust only the insertion position after manual verification.
- Built-in word count updates may not redraw in every situation immediately.
  Mitigation: force refresh on writer mode toggle first, then add a targeted refresh hook only if manual testing shows a real gap.
