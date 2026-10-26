-- Completion and documentation for git config files (.git/config, ~/.gitconfig).
--
-- There is no language server for gitconfig, but git itself knows every valid
-- configuration key (`git help --config`) and documents them all in its manpage.
-- This module turns those two sources into an nvim-cmp source plus a hover.

local M = {}

local api = vim.api
local fn = vim.fn

-- Cached lazily; both shell-outs are done at most once per session.
local keys_cache = nil
local docs_cache = nil

-- git-config(1) only cross-references these sections, so hover sends them to
-- the manpage that actually describes them.
local MANPAGE_BY_SECTION = {
  sendemail = "git-send-email",
  gitweb = "gitweb.conf",
  gitcvs = "git-cvsserver",
}

--- Is a key segment a placeholder like `<name>` / `<base>` / `<pattern>`?
---@param segment string
---@return boolean
local function is_placeholder(segment)
  return segment:match "^<.*>$" ~= nil
end

--- Split a dotted config key into its segments.
---@param key string
---@return string[]
local function segments(key)
  local segs = {}
  for seg in key:gmatch "[^.]+" do
    table.insert(segs, seg)
  end
  return segs
end

--- Every configuration key git knows about, e.g. `core.fileMode`,
--- `branch.<name>.remote`. Empty table if git is unavailable.
---@return string[]
function M.keys()
  if keys_cache then
    return keys_cache
  end

  keys_cache = {}
  local out = fn.systemlist { "git", "help", "--config" }
  if vim.v.shell_error ~= 0 then
    return keys_cache
  end

  for _, line in ipairs(out) do
    -- `git help --config` also prints a trailing prose paragraph; keep only
    -- lines that look like bare dotted keys.
    if line:match "^[%w<>%-_]+%.[%w<>%-_.]+$" then
      table.insert(keys_cache, line)
    end
  end

  return keys_cache
end

--- Unique section names (first segment of every key), sorted.
---@return string[]
function M.sections()
  local seen, out = {}, {}
  for _, key in ipairs(M.keys()) do
    local section = segments(key)[1]
    if section and not seen[section] then
      seen[section] = true
      table.insert(out, section)
    end
  end
  table.sort(out)
  return out
end

-- Indentation the manpage uses: top-level entries at 7, their body at 11,
-- nested sub-entries (the children of a `foo.*` entry) at 11 with body at 15.
local ENTRY_INDENT = 7
local BODY_INDENT = 11
local SUB_BODY_INDENT = 15

--- A manpage entry line may list several keys sharing one description, e.g.
--- `user.name, user.email, author.name, ...`.
---@param content string
---@return string[]|nil
local function parse_entry_keys(content)
  -- Entries may carry a trailing annotation: `add.ignoreErrors, ... (deprecated)`.
  content = content:gsub("%s*%b()$", "")

  local keys = {}
  for part in content:gmatch "[^,]+" do
    local key = vim.trim(part)
    if not key:match "^[%w<>%-_]+%.[%w<>%-_.*]+$" then
      return nil
    end
    table.insert(keys, key)
  end
  return #keys > 0 and keys or nil
end

--- Does a line look like the name of a nested sub-entry rather than prose?
---@param content string
---@return boolean
local function is_sub_entry(content)
  return content:match "^[%w<>%-_]+[%w<>%-_.]*$" ~= nil and content:sub(-1) ~= "."
end

--- Collapse the manpage's hard wrapping back into paragraphs.
---@param lines string[]
---@return string
local function join_paragraphs(lines)
  local text = table.concat(lines, "\n"):gsub("\n\n+", "\0"):gsub("\n", " "):gsub("%z", "\n\n")
  return vim.trim(text)
end

--- Key -> description, parsed out of `man git-config`.
---@return table<string, string>
function M.docs()
  if docs_cache then
    return docs_cache
  end

  docs_cache = {}
  local out = fn.systemlist { "env", "MANWIDTH=100", "MANPAGER=cat", "man", "git-config" }
  if vim.v.shell_error ~= 0 then
    return docs_cache
  end

  local current_keys, lines = {}, {}
  local body_indent = BODY_INDENT
  -- Set while a wildcard entry (`advice.*`) is open; its children are listed
  -- unqualified, so they need this prefix to become real keys.
  local prefix = nil
  local prev_blank = true

  local function flush()
    if #current_keys > 0 and #lines > 0 then
      local text = join_paragraphs(lines)
      if text ~= "" then
        for _, key in ipairs(current_keys) do
          docs_cache[key:lower()] = text
        end
      end
    end
    current_keys, lines = {}, {}
  end

  for _, line in ipairs(out) do
    local indent = #line:match "^ *"
    local content = vim.trim(line)

    if content == "" then
      if #current_keys > 0 then
        table.insert(lines, "")
      end
      prev_blank = true
    else
      local entry_keys = indent == ENTRY_INDENT and parse_entry_keys(content) or nil

      if entry_keys then
        flush()
        current_keys = entry_keys
        body_indent = BODY_INDENT
        prefix = #entry_keys == 1 and entry_keys[1]:sub(-2) == ".*" and entry_keys[1]:sub(1, -2) or nil
      elseif prefix and indent == BODY_INDENT and prev_blank and is_sub_entry(content) then
        flush()
        current_keys = { prefix .. content }
        body_indent = SUB_BODY_INDENT
      elseif #current_keys > 0 and indent >= body_indent then
        table.insert(lines, content)
      else
        flush()
        if indent <= ENTRY_INDENT then
          prefix = nil
        end
      end

      prev_blank = false
    end
  end
  flush()

  return docs_cache
end

-- Documented keys containing a placeholder (`color.branch.<slot>`, `advice.*`),
-- as Lua patterns, most specific first.
local wildcards_cache = nil

---@return { pattern: string, key: string }[]
local function wildcards()
  if wildcards_cache then
    return wildcards_cache
  end

  wildcards_cache = {}
  for key in pairs(M.docs()) do
    if key:find "[<*]" then
      local parts, holes = {}, 0
      for _, seg in ipairs(segments(key)) do
        if is_placeholder(seg) or seg == "*" then
          table.insert(parts, "[^.]+")
          holes = holes + 1
        else
          table.insert(parts, (seg:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")))
        end
      end
      table.insert(wildcards_cache, {
        pattern = "^" .. table.concat(parts, "%.") .. "$",
        key = key,
        holes = holes,
      })
    end
  end

  -- Fewer placeholders means a more specific entry; prefer those.
  table.sort(wildcards_cache, function(a, b)
    if a.holes ~= b.holes then
      return a.holes < b.holes
    end
    return #a.key > #b.key
  end)

  return wildcards_cache
end

--- Documentation for a single key, falling back to the wildcard entry that
--- covers it (`color.branch.current` -> `color.branch.<slot>`).
---@param key string
---@return string|nil
function M.doc(key)
  local docs = M.docs()
  local lower = key:lower()
  if docs[lower] then
    return docs[lower]
  end

  for _, entry in ipairs(wildcards()) do
    if lower:match(entry.pattern) then
      return docs[entry.key]
    end
  end
  return nil
end

--- The `[section "subsection"]` header enclosing a line.
---@param bufnr integer
---@param lnum integer 1-indexed; the header itself is searched above it
---@return { section: string, subsection: string|nil }|nil
function M.context(bufnr, lnum)
  local lines = api.nvim_buf_get_lines(bufnr, 0, lnum, false)
  for i = #lines, 1, -1 do
    local header = lines[i]:match "^%s*%[(.-)%]"
    if header then
      local section, subsection = header:match '^([%w%-_.]+)%s+"(.*)"$'
      if section then
        return { section = section, subsection = subsection }
      end
      -- Also accept the deprecated `[section.subsection]` spelling.
      section, subsection = header:match "^([%w%-_]+)%.(.+)$"
      if section then
        return { section = section, subsection = subsection }
      end
      if header:match "^[%w%-_]+$" then
        return { section = header }
      end
      return nil
    end
  end
  return nil
end

--- Completion candidates for a position in a gitconfig buffer.
---@param bufnr integer
---@param lnum integer 1-indexed
---@return { label: string, key: string, detail: string }[]
function M.candidates(bufnr, lnum)
  local line = api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  local out = {}

  -- On a section header line: complete section names.
  if line:match "^%s*%[" then
    for _, section in ipairs(M.sections()) do
      table.insert(out, { label = section, key = section, detail = "section" })
    end
    return out
  end

  local ctx = M.context(bufnr, lnum)

  -- Outside any section there is no valid variable, so offer the fully
  -- qualified keys instead — still useful, e.g. when writing include paths.
  if not ctx then
    for _, key in ipairs(M.keys()) do
      table.insert(out, { label = key, key = key, detail = "git config" })
    end
    return out
  end

  local want = ctx.section:lower()
  for _, key in ipairs(M.keys()) do
    local segs = segments(key)
    if #segs >= 2 and segs[1]:lower() == want then
      local rest
      if ctx.subsection then
        -- `[branch "main"]` matches `branch.<name>.remote`.
        if #segs >= 3 and is_placeholder(segs[2]) then
          rest = table.concat(segs, ".", 3)
        end
      elseif not is_placeholder(segs[2]) then
        rest = table.concat(segs, ".", 2)
      end

      -- A bare placeholder (`alias.<name>`) is a user-chosen name, not a
      -- variable we can suggest.
      if rest and not is_placeholder(rest) then
        table.insert(out, { label = rest, key = key, detail = key })
      end
    end
  end

  return out
end

--- Fully qualified key under the cursor, resolved through the section header.
---@return string|nil
local function key_at_cursor()
  local bufnr = api.nvim_get_current_buf()
  local lnum = api.nvim_win_get_cursor(0)[1]
  local line = api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""

  -- On a header line, the section itself is the subject.
  local header = line:match "^%s*%[(.-)%]"
  if header then
    return (header:match "^[%w%-_.]+")
  end

  local name = line:match "^%s*([%w%-_.]+)%s*="
  if not name then
    return nil
  end

  local ctx = M.context(bufnr, lnum)
  if not ctx then
    return name
  end
  if ctx.subsection then
    return ctx.section .. ".<name>." .. name
  end
  return ctx.section .. "." .. name
end

--- Show documentation for the key under the cursor in a floating window.
function M.hover()
  local key = key_at_cursor()
  if not key then
    vim.notify("gitconfig: no config key under cursor", vim.log.levels.INFO)
    return
  end

  local doc = M.doc(key)
  if not doc then
    -- Section headers have no entry of their own, and a few sections are only
    -- cross-referenced from git-config(1); open the relevant manpage instead.
    local section = (key:match "^[^.]+" or ""):lower()
    local page = MANPAGE_BY_SECTION[section] or "git-config"
    vim.cmd("Man " .. page)
    fn.search(key:gsub("%.", "\\."), "w")
    return
  end

  local lines = { "# " .. key, "" }
  vim.list_extend(lines, vim.split(doc, "\n"))
  vim.lsp.util.open_floating_preview(lines, "markdown", {
    border = "single",
    max_width = 80,
    wrap = true,
    focus_id = "gitconfig-doc",
  })
end

--- nvim-cmp source backed by `git help --config`.
local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:is_available()
  return vim.bo.filetype == "gitconfig"
end

function source:get_debug_name()
  return "gitconfig"
end

function source:get_keyword_pattern()
  -- Keys contain dots (`interactive.useBuiltin`), which cmp's default pattern
  -- would treat as a word boundary.
  return [[\%(\k\|\.\)\+]]
end

function source:complete(params, callback)
  local bufnr = params.context.bufnr
  local lnum = params.context.cursor.line + 1

  local items = {}
  for _, cand in ipairs(M.candidates(bufnr, lnum)) do
    table.insert(items, {
      label = cand.label,
      kind = require("cmp").lsp.CompletionItemKind.Property,
      labelDetails = { description = cand.detail },
      data = { key = cand.key },
    })
  end

  callback { items = items, isIncomplete = false }
end

function source:resolve(item, callback)
  local key = item.data and item.data.key
  local doc = key and M.doc(key)
  if doc then
    item.documentation = { kind = "markdown", value = "**" .. key .. "**\n\n" .. doc }
  end
  callback(item)
end

--- Register the cmp source. Call from nvim-cmp's own config, where cmp is
--- guaranteed to be loaded.
function M.register_cmp_source()
  local ok, cmp = pcall(require, "cmp")
  if ok then
    cmp.register_source("gitconfig", source.new())
  end
end

--- Buffer-local wiring for gitconfig files.
function M.setup()
  api.nvim_create_autocmd("FileType", {
    pattern = "gitconfig",
    group = api.nvim_create_augroup("CustomGitconfig", { clear = true }),
    callback = function(args)
      vim.keymap.set("n", "K", M.hover, {
        buffer = args.buf,
        desc = "gitconfig: show docs for key",
      })
    end,
  })
end

return M
