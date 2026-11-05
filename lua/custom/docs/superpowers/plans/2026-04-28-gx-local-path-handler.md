# gx Local Path Handler Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `gx` open existing local files and directories with `xdg-open` while preserving the current URL, Jira, and search behavior.

**Architecture:** Add a focused local-path helper in `link_utils.lua` for token extraction and path normalization. Then wire that helper into the existing `gx.nvim` handler chain in `plugins.lua` so it only intercepts explicit path-like tokens that resolve on disk and lets `gx.nvim` continue using `xdg-open` for the actual open step.

**Tech Stack:** Neovim Lua, `gx.nvim`, `vim.fn`, `vim.uv`, headless `nvim` verification

---

## File map

- Modify: `link_utils.lua`
  Responsibility: local-path parsing, normalization, existence checks, and `file://` URI construction.
- Modify: `plugins.lua`
  Responsibility: register the new `gx.nvim` handler and preserve existing handler ordering.
- Create: `tests/link_utils_local_path_spec.lua`
  Responsibility: headless Lua assertions for path extraction and normalization behavior.

### Task 1: Add local path helper and focused headless tests

**Files:**
- Modify: `link_utils.lua`
- Create: `tests/link_utils_local_path_spec.lua`

- [ ] **Step 1: Write the failing headless spec**

Create `tests/link_utils_local_path_spec.lua` with this content:

```lua
local repo_root = vim.fn.getcwd()
local original_cwd = vim.uv.cwd()
vim.fn.mkdir(repo_root .. "/tests/tmp-gx/child", "p")
vim.fn.writefile({ "hello" }, repo_root .. "/tests/tmp-gx/example.txt")

vim.cmd("cd " .. vim.fn.fnameescape(repo_root .. "/tests/tmp-gx"))

local link_utils = dofile(repo_root .. "/link_utils.lua")

local function assert_equal(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s\nexpected: %s\nactual: %s", label, expected, tostring(actual)))
  end
end

local file_token = link_utils._extract_local_path_token("see ./example.txt, please")
assert_equal(file_token, "./example.txt", "extracts relative file path")

local dir_token = link_utils._extract_local_path_token("open ./child)")
assert_equal(dir_token, "./child", "trims trailing punctuation")

local resolved_file = link_utils._resolve_local_path("./example.txt")
assert_equal(resolved_file, vim.fn.getcwd() .. "/example.txt", "resolves relative file path")

local resolved_dir = link_utils._resolve_local_path("./child")
assert_equal(resolved_dir, vim.fn.getcwd() .. "/child", "resolves relative directory path")

local missing = link_utils._resolve_local_path("./missing.txt")
assert_equal(missing, nil, "returns nil for missing path")

vim.cmd("cd " .. vim.fn.fnameescape(original_cwd))
vim.fn.delete(repo_root .. "/tests/tmp-gx", "rf")
```

- [ ] **Step 2: Run the spec to verify it fails**

Run:

```bash
nvim --headless -u NONE "+lua dofile('tests/link_utils_local_path_spec.lua')" +qa
```

Expected: FAIL with an error like `attempt to call field '_extract_local_path_token' (a nil value)` because the helper functions do not exist yet.

- [ ] **Step 3: Add the minimal helper implementation**

Update `link_utils.lua` by adding these helpers before `return M`:

```lua
local function trim_path_token(token)
  return token and token:gsub("[%,%)%]%}%>]+$", "") or nil
end

function M._extract_local_path_token(line)
  local patterns = {
    "([~%.][%w%._%+%-%/]+)",
    "(/[%w%._%+%-%/]+)",
  }

  for _, pattern in ipairs(patterns) do
    local match = line:match(pattern)
    match = trim_path_token(match)
    if match and (match:match("^~/") or match:match("^%./") or match:match("^%.%./") or match:match("^/")) then
      return match
    end
  end
end

function M._resolve_local_path(token)
  if not token or token == "" then
    return nil
  end

  local expanded = vim.fn.expand(token)
  local absolute = vim.fn.fnamemodify(expanded, ":p")
  if vim.uv.fs_stat(absolute) then
    return absolute:gsub("/$", "")
  end
end

function M._local_path_to_uri(token)
  local path = M._resolve_local_path(token)
  if not path then
    return nil
  end

  return "file://" .. path
end
```

Notes for the implementation while editing:

- Keep the helpers small and local to this file.
- Preserve all existing smart-link functions.
- The underscore-prefixed helpers are intentionally exposed only for headless verification.
- Keep the extraction helper independent of `gx.nvim` internals so it can be tested with `nvim --headless -u NONE`.

- [ ] **Step 4: Re-run the spec and verify it passes**

Run:

```bash
nvim --headless -u NONE "+lua dofile('tests/link_utils_local_path_spec.lua')" +qa
```

Expected: command exits successfully with no Lua errors.

- [ ] **Step 5: Commit Task 1**

```bash
git add link_utils.lua tests/link_utils_local_path_spec.lua
git commit -m "feat: add local path gx helpers"
```

### Task 2: Wire the helper into the existing gx.nvim handler chain

**Files:**
- Modify: `plugins.lua`

- [ ] **Step 1: Write the failing integration check command**

Plan to verify that `plugins.lua` can load after the handler is added by running a headless Lua parse/load command against the modified files.

Use this command as the failure check once the code edit is in place:

```bash
nvim --headless "+lua dofile(vim.fn.getcwd() .. '/link_utils.lua'); assert(loadfile(vim.fn.getcwd() .. '/plugins.lua'))" +qa
```

Expected before the edit: this command is not yet meaningful because the handler is absent. The practical failing signal for this task is that `gx` still cannot open a local path manually.

- [ ] **Step 2: Add the local path handler in `plugins.lua`**

Inside the existing `require("gx").setup { handlers = { ... } }` block, add a new handler before `search = true` and require `custom.link_utils` once near the top of the `config` function:

```lua
config = function()
  local link_utils = require "custom.link_utils"

  require("gx").setup {
    open_browser_app = "xdg-open",
    handlers = {
      plugin = true,
      github = true,
      package_json = true,
      local_path = {
        name = "local_path",
        handle = function(mode, line, _)
          local token = link_utils._extract_local_path_token(line)
          return link_utils._local_path_to_uri(token)
        end,
      },
      search = true,
      go = true,
      jira = {
        name = "jira",
        handle = function(mode, line, _)
          local ticket = require("gx.helper").find(line, mode, "(%u+-%d+)")
          if ticket and #ticket < 20 then
            return "https://piwikpro.atlassian.net/browse/" .. ticket
          end
        end,
      },
    },
  }
end,
```

Implementation note: `gx.nvim` already shells out through `xdg-open` with the returned URL, so the handler should only return a `file://` URI for valid local paths and otherwise return `nil`.

- [ ] **Step 3: Run syntax/load verification**

Run:

```bash
nvim --headless "+lua dofile(vim.fn.getcwd() .. '/link_utils.lua'); assert(loadfile(vim.fn.getcwd() .. '/plugins.lua'))" +qa
```

Expected: command exits successfully with no syntax errors.

- [ ] **Step 4: Manually verify handler behavior in Neovim**

Run these manual checks in a real Neovim session opened at `~/.config/nvim/lua/custom`:

```text
1. Open a scratch buffer or note containing ~/brainstorm and press gx.
2. Open a scratch buffer containing /home/jzy/Downloads/20260328_161809.mp4 and press gx.
3. Open a scratch buffer containing ./README.md from the custom repo and press gx.
4. Open a scratch buffer containing https://github.com and press gx.
5. Open a scratch buffer containing PROJ-123 and press gx.
6. Open a scratch buffer containing random words and press gx.
```

Expected:

- Existing files and directories open with the desktop app or file manager.
- URLs still open in the browser.
- Jira keys still resolve to Jira.
- Random text still uses the search fallback.

- [ ] **Step 5: Commit Task 2**

```bash
git add plugins.lua
git commit -m "feat: open local paths with gx"
```

### Task 3: Final verification sweep

**Files:**
- Test: `tests/link_utils_local_path_spec.lua`
- Verify: `link_utils.lua`
- Verify: `plugins.lua`

- [ ] **Step 1: Run the focused headless spec again**

Run:

```bash
nvim --headless -u NONE "+lua dofile('tests/link_utils_local_path_spec.lua')" +qa
```

Expected: PASS with exit code 0.

- [ ] **Step 2: Run the syntax/load verification again**

Run:

```bash
nvim --headless "+lua dofile(vim.fn.getcwd() .. '/link_utils.lua'); assert(loadfile(vim.fn.getcwd() .. '/plugins.lua'))" +qa
```

Expected: PASS with exit code 0.

- [ ] **Step 3: Check git status for the final diff**

Run:

```bash
git status --short
```

Expected: only the intended `gx` local-path changes are present, along with any unrelated pre-existing user changes left untouched.

- [ ] **Step 4: Commit final verification state if needed**

If Task 2 already contains the final implementation with no additional edits, skip a new commit. If verification required a last small fix, commit it with:

```bash
git add link_utils.lua plugins.lua tests/link_utils_local_path_spec.lua
git commit -m "fix: polish gx local path handling"
```
