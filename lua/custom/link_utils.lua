local M = {}

local local_path_prefixes = { "~/", "../", "./", "/" }

local function trim_local_path_punctuation(path)
  return path:gsub("[`',.:%]%)]*$", "")
end

local function match_local_path_token(text, index)
  return text:match("[^%s%]%)]+", index)
end

local function has_local_path_prefix(path)
  for _, prefix in ipairs(local_path_prefixes) do
    if path:sub(1, #prefix) == prefix then
      return true
    end
  end

  return false
end

local function is_local_path_boundary(text, index)
  if index == 1 then
    return true
  end

  return text:sub(index - 1, index - 1):match "[%s%[(`]" ~= nil
end

function M._extract_local_path_token(text)
  if type(text) ~= "string" then
    return nil
  end

  local earliest_index
  local earliest_token

  for _, prefix in ipairs(local_path_prefixes) do
    local search_start = 1

    while true do
      local index = text:find(prefix, search_start, true)
      if not index then
        break
      end

      if is_local_path_boundary(text, index) then
        local token = match_local_path_token(text, index)
        if token then
          token = trim_local_path_punctuation(token)
          if not earliest_index or index < earliest_index then
            earliest_index = index
            earliest_token = token
          end
        end
      end

      search_start = index + 1
    end
  end

  return earliest_token
end

function M._extract_local_path_token_at_col(text, col)
  if type(text) ~= "string" or type(col) ~= "number" then
    return nil
  end

  for _, prefix in ipairs(local_path_prefixes) do
    local search_start = 1

    while true do
      local index = text:find(prefix, search_start, true)
      if not index then
        break
      end

      if is_local_path_boundary(text, index) then
        local token = match_local_path_token(text, index)
        if token then
          token = trim_local_path_punctuation(token)
          local last_index = index + #token - 1
          if col >= index and col <= last_index then
            return token
          end
        end
      end

      search_start = index + 1
    end
  end

  return nil
end

function M._resolve_local_path(path)
  if type(path) ~= "string" then
    return nil
  end

  path = trim_local_path_punctuation(path)
  if not has_local_path_prefix(path) then
    return nil
  end

  local expanded_path = path:sub(1, 2) == "~/" and vim.fn.expand(path) or path
  local absolute_path = vim.fn.fnamemodify(expanded_path, ":p")

  if vim.loop.fs_stat(absolute_path) then
    return absolute_path
  end

  return nil
end

function M._local_path_to_uri(path)
  local absolute_path = M._resolve_local_path(path)
  if not absolute_path then
    return nil
  end

  return vim.uri_from_fname(absolute_path)
end

local function get_url_host(url)
  local host = url:match "https?://([^/%?#]+)"
  return host and host:gsub("^www%.", "") or nil
end

local html_entities = {
  lt = "<",
  gt = ">",
  quot = '"',
  apos = "'",
  nbsp = " ",
  ndash = "–",
  mdash = "—",
  hellip = "…",
  lsquo = "‘",
  rsquo = "’",
  ldquo = "“",
  rdquo = "”",
  laquo = "«",
  raquo = "»",
}

local function decode_html_entities(text)
  text = text:gsub("&#[xX](%x+);", function(hex)
    return vim.fn.nr2char(tonumber(hex, 16), true)
  end)
  text = text:gsub("&#(%d+);", function(dec)
    return vim.fn.nr2char(tonumber(dec), true)
  end)
  text = text:gsub("&(%a+);", function(name)
    return html_entities[name]
  end)
  -- Last, so "&amp;lt;" ends up as "&lt;" and not "<"
  return (text:gsub("&amp;", "&"))
end

local max_title_chars = 80

-- Turn a raw title into text that is safe inside "[...]" (also in a table cell)
function M._clean_title(title)
  if type(title) ~= "string" then
    return nil
  end

  title = decode_html_entities(title)
  title = title:gsub("%s+", " "):gsub("%c", ""):gsub("^ ", ""):gsub(" $", "")
  if title == "" then
    return nil
  end

  if vim.fn.strchars(title) > max_title_chars then
    title = vim.fn.strcharpart(title, 0, max_title_chars - 1):gsub(" $", "") .. "…"
  end

  -- The title is text from a stranger. Escape the backslash too: otherwise a title
  -- like "x\\](https://evil)" closes the link text early and swaps the target.
  -- "<" and ">" are escaped so a title cannot put HTML (e.g. a remote <img>) in the note.
  return (title:gsub("[\\%[%]|<>]", "\\%0"))
end

-- Page title from HTML: og:title if present (no " | Site" suffix), else <title>
function M._extract_title(html)
  if type(html) ~= "string" then
    return nil
  end

  for meta in html:gmatch "<[mM][eE][tT][aA]%s[^>]*>" do
    if meta:match "[\"']og:title[\"']" then
      local title = M._clean_title(meta:match 'content%s*=%s*"([^"]*)"' or meta:match "content%s*=%s*'([^']*)'")
      if title then
        return title
      end
    end
  end

  return M._clean_title(html:match "<[tT][iI][tT][lL][eE][^>]*>(.-)</[tT][iI][tT][lL][eE]>")
end

local fetch_timeout_s = 2
local max_html_bytes = 200 * 1024

-- Blocks for up to fetch_timeout_s. Returns nil when the page gives no usable title.
local function fetch_page_title(url)
  local ok, job = pcall(vim.system, {
    "curl",
    "--silent",
    "--location",
    "--compressed",
    -- Take the URL literally: curl would expand "[1-100]" or "{a,b}" into many requests
    "--globoff",
    -- A redirect must not lead to another scheme
    "--proto",
    "=http,https",
    "--proto-redir",
    "=http,https",
    "--max-redirs",
    "5",
    "--max-filesize",
    "5M",
    "--max-time",
    tostring(fetch_timeout_s),
    "--user-agent",
    "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0",
    "--",
    url,
  }, { text = false })
  if not ok then
    return nil
  end

  -- On a timeout curl still hands over what it got, and <title> sits at the top
  local result = job:wait((fetch_timeout_s + 1) * 1000)
  local html = result.stdout
  if not html or html == "" then
    return nil
  end

  return M._extract_title(html:sub(1, max_html_bytes))
end

-- Helper function to get and validate clipboard URL
local function get_clipboard_url()
  -- Get clipboard content
  local clipboard_content = vim.fn.getreg "+"
  if not clipboard_content or clipboard_content == "" then
    vim.notify("No URL in clipboard detected", vim.log.levels.WARN)
    return nil
  end

  -- Clean the clipboard content (remove whitespace)
  clipboard_content = clipboard_content:gsub("^%s*(.-)%s*$", "%1")

  -- Basic URL validation
  if not clipboard_content:match "^https?://" then
    vim.notify("No valid URL in clipboard detected", vim.log.levels.WARN)
    return nil
  end

  return clipboard_content
end

-- Helper function to determine link text based on URL.
-- fetch_title: for a site without its own rule, ask the page for its title (network request)
local function get_link_text(url, fetch_title)
  local link_text = "web" -- default

  if url:match "github%.com/[^/]+/[^/]+/issues/(%d+)" then
    local owner, repo, issue_id = url:match "github%.com/([^/]+)/([^/]+)/issues/(%d+)"
    link_text = string.format("%s/%s/issues/%s", owner, repo, issue_id)
  elseif url:match "github%.com/[^/]+/[^/]+/pull/%d+/commits/[a-f0-9]+" then
    local owner, repo, pr_id, commit_hash = url:match "github%.com/([^/]+)/([^/]+)/pull/(%d+)/commits/([a-f0-9]+)"
    local short_rev = commit_hash:sub(1, 6)
    link_text = string.format("%s/%s/pull/%s - %s", owner, repo, pr_id, short_rev)
  elseif url:match "github%.com/[^/]+/[^/]+/commit/[a-f0-9]+" then
    local owner, repo, commit_hash = url:match "github%.com/([^/]+)/([^/]+)/commit/([a-f0-9]+)"
    local short_rev = commit_hash:sub(1, 6)
    link_text = string.format("%s/%s - %s", owner, repo, short_rev)
  elseif url:match "github%.com/[^/]+/[^/]+/pull/(%d+)" then
    local owner, repo, pr_id = url:match "github%.com/([^/]+)/([^/]+)/pull/(%d+)"
    link_text = string.format("%s/%s/pull/%s", owner, repo, pr_id)
  elseif url:match "github%.com/[^/]+/[^/]+/actions" then
    local owner, repo = url:match "github%.com/([^/]+)/([^/]+)/actions"
    link_text = string.format("%s/%s/actions", owner, repo)
  elseif url:match "github%.com/[^/]+/[^/]+/releases" then
    local owner, repo = url:match "github%.com/([^/]+)/([^/]+)/releases"
    link_text = string.format("%s/%s/releases", owner, repo)
  elseif url:match "github%.com/[^/]+/[^/]+/?$" then
    local owner, repo = url:match "github%.com/([^/]+)/([^/]+)/?$"
    link_text = string.format("%s/%s", owner, repo)
  elseif url:match "github%.com" then
    link_text = "github"
  elseif url:match "atlassian%.net/wiki/" then
    local clean_url = url:gsub("[?#].*$", "")
    if url:match "/pages/" then
      local is_edit_url = clean_url:match "/pages/edit"
      local last_segment = clean_url:match "/([^/]+)$"
      if is_edit_url or (last_segment and last_segment:match "^%d+$") then
        link_text = get_url_host(url) or "confluence"
      else
        link_text = last_segment and last_segment:gsub("%+", " ") or "confluence"
      end
    else
      link_text = "confluence"
    end
  elseif url:match "atlassian%.net/browse/" then
    local ticket = url:match "atlassian%.net/browse/([^/?#]+)"
    link_text = ticket or "jira"
  elseif url:match "atlassian%.net/issues/" then
    local ticket = url:match "atlassian%.net/issues/([^/?#]+)"
    link_text = ticket or "jira"
  elseif url:match "miro%.com" then
    link_text = "miro"
  elseif url:match "slack%.com" then
    link_text = "slack"
  else
    -- Extract domain name without TLD extension for default case
    local domain = get_url_host(url)
    if domain then
      -- Extract the main domain name (before the TLD)
      local domain_name = domain:match "([^%.]+)"
      if domain_name then
        link_text = domain_name
      end
    end

    if fetch_title then
      link_text = fetch_page_title(url) or link_text
    end
  end

  return link_text
end

-- before_cursor: false pastes like 'p' (after the cursor), true like 'P'
local function paste_smart_link(before_cursor, fetch_title)
  -- Check if we're in a markdown file
  local filetype = vim.bo.filetype
  if filetype ~= "markdown" and filetype ~= "mdx" then
    vim.notify("Smart link paste only works in markdown files", vim.log.levels.WARN)
    return
  end

  local clipboard_content = get_clipboard_url()
  if not clipboard_content then
    return
  end

  local link_text = get_link_text(clipboard_content, fetch_title)
  local markdown_link = string.format("[%s](%s)", link_text, clipboard_content)

  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_line = vim.api.nvim_get_current_line()
  local col = cursor_pos[2]

  -- Split the line at cursor position and insert the link
  local before = current_line:sub(1, col)
  local after = current_line:sub(col + 1)

  if before_cursor then
    vim.api.nvim_set_current_line(before .. markdown_link .. " " .. after)
    vim.api.nvim_win_set_cursor(0, { cursor_pos[1], col + #markdown_link })
  else
    vim.api.nvim_set_current_line(before .. " " .. markdown_link .. after)
    vim.api.nvim_win_set_cursor(0, { cursor_pos[1], col + 1 + #markdown_link })
  end
end

M.smart_link_paste = function()
  paste_smart_link(false)
end

M.smart_link_paste_before = function()
  paste_smart_link(true)
end

-- Like smart_link_paste, but fetches the page title. Kept on its own key so that a
-- request goes out only when asked for: fetching a one-time link can use it up.
M.smart_link_paste_with_title = function()
  paste_smart_link(false, true)
end

M.paste_as_codeblock = function()
  local clipboard = vim.fn.getreg "+"
  if not clipboard or clipboard == "" then
    vim.notify("Clipboard is empty", vim.log.levels.WARN)
    return
  end
  -- Remove trailing newline if present
  clipboard = clipboard:gsub("\n$", "")
  local lines = { "```" }
  for line in (clipboard .. "\n"):gmatch "(.-)\n" do
    table.insert(lines, line)
  end
  table.insert(lines, "```")
  vim.api.nvim_put(lines, "l", true, true)
end

M.wrap_codeblock = function()
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  vim.api.nvim_buf_set_lines(0, end_line, end_line, false, { "```" })
  vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, false, { "```" })
end

return M
