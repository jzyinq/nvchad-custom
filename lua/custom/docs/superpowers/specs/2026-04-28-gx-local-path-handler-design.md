# gx local path handler design

## Summary

Extend the existing `gx.nvim` setup so `gx` can open local filesystem paths with `xdg-open` while preserving the current URL, Jira, plugin, package, Go, and search behaviors.

## Goals

- Keep the existing `gx` mapping unchanged.
- Support local paths in notes and any other buffer where `gx` is used.
- Open both files and directories with `xdg-open`.
- Fall back to existing `gx.nvim` handlers when the text under cursor is not a valid local path.

## Non-goals

- Replacing `gx.nvim` with a custom implementation.
- Changing how web URLs, Jira keys, or search fallback work.
- Adding special UI beyond normal `gx` behavior.

## Chosen approach

Add a custom `gx.nvim` handler for local paths inside `lua/custom/plugins.lua`, alongside the existing Jira handler.

The handler will:

- Look for path-like text under the cursor or current selection.
- Recognize `~/...`, absolute paths like `/home/jzy/...`, and relative paths like `./...` and `../...`.
- Expand `~` to the user's home directory.
- Resolve relative paths against Neovim's current working directory.
- Check whether the resolved path exists on disk.
- If it exists, open it with `xdg-open`.
- If it does not exist or no path-like text is found, return nothing so the rest of the `gx.nvim` handler chain continues unchanged.

## Alternatives considered

### Replace `gx` with a custom mapping

This would provide full control, but it would duplicate existing `gx.nvim` behavior and add more maintenance burden for no practical benefit.

### Add a separate path-opening mapping

This would avoid touching `gx`, but it makes the workflow less ergonomic and splits similar "open target under cursor" behavior across multiple keys.

## Implementation details

### Location

Keep the change in `lua/custom/plugins.lua` to match the existing `gx.nvim` configuration and avoid touching NvChad core files.

If the helper logic becomes longer than a small local function, move only the parsing/opening helper into `lua/custom/link_utils.lua` and call it from the handler.

### Detection rules

The handler should prefer a conservative match so it does not steal normal URL behavior.

It should recognize tokens that begin with:

- `~/`
- `/`
- `./`
- `../`

It should trim surrounding punctuation that is common in notes, such as trailing commas, closing parentheses, or closing brackets, before checking the path on disk.

### Opening behavior

Use `xdg-open` for both files and directories.

The handler should use a non-blocking Neovim job API so opening a file manager or media file does not freeze the editor.

### Error handling

- If the text looks like a path but does not exist, do not show an error by default; allow `gx.nvim` to keep trying its other handlers.
- If `xdg-open` itself fails after a verified existing path, show a notification so the failure is visible.

## Data flow

1. User presses `gx`.
2. `gx.nvim` invokes handlers in configured order.
3. Local path handler inspects cursor text or selection.
4. If it finds and resolves an existing path, it opens the path with `xdg-open` and stops further handling.
5. Otherwise, existing handlers continue, including Jira and the generic search fallback.

## Testing

Verify these cases manually in Neovim:

- `gx` on `~/brainstorm`
- `gx` on `/home/jzy/Downloads/20260328_161809.mp4`
- `gx` on an existing directory path
- `gx` on a relative path like `./README.md`
- `gx` on a normal `https://...` URL
- `gx` on a Jira ticket like `PROJ-123`
- `gx` on random text to confirm search fallback still works

## Risks and mitigations

- Overmatching note text as a filesystem path.
  Mitigation: only handle explicit path prefixes and require the resolved path to exist.
- Blocking Neovim while opening external applications.
  Mitigation: use Neovim's async job API rather than a blocking shell call.
