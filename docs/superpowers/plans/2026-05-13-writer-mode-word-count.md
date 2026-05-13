# Writer Mode Word Count Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a `current/750` word counter in the NvChad statusline only while writer mode is enabled, and turn it green at or above the threshold.

**Architecture:** Keep the existing `<leader>W` toggle and add one focused helper module for statusline formatting. Inject that helper into NvChad's default statusline through `ui.statusline.overriden_modules`, and add only the highlight groups and redraw hook needed for immediate updates.

**Tech Stack:** Neovim Lua, NvChad statusline, `vim.fn.wordcount()`, Base46 highlights, headless `nvim` verification

---

## File map

- Create: `writer_mode.lua`
  Responsibility: writer-mode statusline segment generation based on `vim.g.writer_mode` and `vim.fn.wordcount()`.
- Modify: `chadrc.lua`
  Responsibility: inject the custom writer-mode segment into NvChad's statusline module list.
- Modify: `highlights.lua`
  Responsibility: add normal and success highlight groups for the word counter.
- Modify: `mappings.lua`
  Responsibility: refresh the statusline immediately after toggling writer mode.
- Create: `tests/writer_mode_statusline_spec.lua`
  Responsibility: headless verification for segment rendering and threshold color selection.

### Task 1: Add a focused writer mode statusline helper with headless tests

**Files:**
- Create: `writer_mode.lua`
- Create: `tests/writer_mode_statusline_spec.lua`

- [ ] **Step 1: Write the failing headless spec**

Create `tests/writer_mode_statusline_spec.lua` with this content:

```lua
local repo_root = vim.fn.getcwd()
local writer_mode = dofile(repo_root .. "/writer_mode.lua")

local function assert_equal(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s\nexpected: %s\nactual: %s", label, expected, tostring(actual)))
  end
end

local original_wordcount = vim.fn.wordcount
local original_writer_mode = vim.g.writer_mode

vim.fn.wordcount = function()
  return { words = 20 }
end

vim.g.writer_mode = false
assert_equal(writer_mode.statusline_segment(), "", "returns empty string when writer mode is disabled")

vim.g.writer_mode = true
assert_equal(
  writer_mode.statusline_segment(),
  "%#St_writerWordCount# 20/750 ",
  "renders default segment below threshold"
)

vim.fn.wordcount = function()
  return { words = 750 }
end

assert_equal(
  writer_mode.statusline_segment(),
  "%#St_writerWordCountReached# 750/750 ",
  "renders success segment at threshold"
)

vim.fn.wordcount = original_wordcount
vim.g.writer_mode = original_writer_mode
```

- [ ] **Step 2: Run the spec to verify it fails**

Run:

```bash
nvim --headless -u NONE "+lua dofile('tests/writer_mode_statusline_spec.lua')" +qa
```

Expected: FAIL with an error like `cannot open writer_mode.lua` or `attempt to call field 'statusline_segment'` because the helper does not exist yet.

- [ ] **Step 3: Write the minimal helper implementation**

Create `writer_mode.lua` with this content:

```lua
local M = {}

local THRESHOLD = 750

function M.statusline_segment()
  if not vim.g.writer_mode then
    return ""
  end

  local count = vim.fn.wordcount().words or 0
  local group = count >= THRESHOLD and "St_writerWordCountReached" or "St_writerWordCount"

  return string.format("%%#%s# %d/%d ", group, count, THRESHOLD)
end

return M
```

- [ ] **Step 4: Re-run the spec and verify it passes**

Run:

```bash
nvim --headless -u NONE "+lua dofile('tests/writer_mode_statusline_spec.lua')" +qa
```

Expected: command exits successfully with no Lua errors.

- [ ] **Step 5: Commit Task 1**

```bash
git add writer_mode.lua tests/writer_mode_statusline_spec.lua
git commit -m "feat: add writer mode word count helper"
```

### Task 2: Wire the segment into NvChad statusline and writer mode toggle

**Files:**
- Modify: `chadrc.lua`
- Modify: `highlights.lua`
- Modify: `mappings.lua`

- [ ] **Step 1: Add the statusline hook in `chadrc.lua`**

Update `chadrc.lua` so `M.ui.statusline` defines `overriden_modules` and inserts the new segment just before `cwd()` and `cursor_position()`:

```lua
local writer_mode = require "custom.writer_mode"

M.ui = {
  theme = "onedark",
  theme_toggle = { "bearded-arc", "one_light" },
  statusline = {
    overriden_modules = function(modules)
      table.insert(modules, 11, writer_mode.statusline_segment())
    end,
  },

  hl_override = highlights.override,
  hl_add = highlights.add,
  nvdash = {
    load_on_startup = false,
    header = {
      "                                                     ",
      "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
      "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
      "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
      "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
      "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
      "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
      "                                                     ",
    },
  },
}
```

- [ ] **Step 2: Add counter highlight groups in `highlights.lua`**

Extend `M.add` with:

```lua
M.add = {
  NvimTreeOpenedFolderName = { fg = "green", bold = true },
  St_writerWordCount = { fg = "light_grey", bg = "statusline_bg" },
  St_writerWordCountReached = { fg = "green", bg = "statusline_bg", bold = true },
}
```

- [ ] **Step 3: Refresh the statusline in `mappings.lua`**

Update the `<leader>W` handler so both branches redraw the statusline after changing `vim.g.writer_mode`:

```lua
if vim.g.writer_mode then
  vim.g.writer_mode = false
  vim.opt.textwidth = 0
  cmp.setup { enabled = true }
  vim.cmd.redrawstatus()
  vim.notify("Writer Mode disabled", vim.log.levels.INFO, { title = "Writer Mode" })
else
  vim.g.writer_mode = true
  vim.opt.textwidth = 80
  cmp.setup { enabled = false }
  vim.cmd.redrawstatus()
  vim.notify("Writer Mode enabled", vim.log.levels.INFO, { title = "Writer Mode" })
end
```

- [ ] **Step 4: Run syntax/load verification**

Run:

```bash
nvim --headless "+lua assert(loadfile(vim.fn.getcwd() .. '/writer_mode.lua')); assert(loadfile(vim.fn.getcwd() .. '/chadrc.lua')); assert(loadfile(vim.fn.getcwd() .. '/highlights.lua')); assert(loadfile(vim.fn.getcwd() .. '/mappings.lua'))" +qa
```

Expected: command exits successfully with no syntax errors.

- [ ] **Step 5: Commit Task 2**

```bash
git add chadrc.lua highlights.lua mappings.lua
git commit -m "feat: show writer mode word count in statusline"
```

### Task 3: Run final verification in headless and interactive Neovim

**Files:**
- Test: `tests/writer_mode_statusline_spec.lua`
- Verify: `writer_mode.lua`
- Verify: `chadrc.lua`
- Verify: `highlights.lua`
- Verify: `mappings.lua`

- [ ] **Step 1: Run the focused headless spec again**

Run:

```bash
nvim --headless -u NONE "+lua dofile('tests/writer_mode_statusline_spec.lua')" +qa
```

Expected: PASS with exit code 0.

- [ ] **Step 2: Run the syntax/load verification again**

Run:

```bash
nvim --headless "+lua assert(loadfile(vim.fn.getcwd() .. '/writer_mode.lua')); assert(loadfile(vim.fn.getcwd() .. '/chadrc.lua')); assert(loadfile(vim.fn.getcwd() .. '/highlights.lua')); assert(loadfile(vim.fn.getcwd() .. '/mappings.lua'))" +qa
```

Expected: PASS with exit code 0.

- [ ] **Step 3: Manually verify behavior in Neovim**

Manual checks in a normal Neovim session opened at `~/.config/nvim/lua/custom`:

```text
1. Open a markdown or journal buffer and press <leader>W.
2. Confirm the statusline shows X/750 immediately.
3. Type words and confirm the count updates while editing.
4. Confirm the segment stays neutral below 750.
5. Confirm the segment turns green at 750 or above.
6. Press <leader>W again and confirm the counter disappears immediately.
```

Expected: all checks behave as described in the spec.

- [ ] **Step 4: Commit Task 3**

```bash
git add writer_mode.lua chadrc.lua highlights.lua mappings.lua tests/writer_mode_statusline_spec.lua
git commit -m "test: verify writer mode word count integration"
```
