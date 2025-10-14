local M = {}

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

-- Helper function to determine link text based on URL
local function get_link_text(url)
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
    link_text = "confluence"
  elseif url:match "atlassian%.net/browse/" then
    link_text = "jira"
  elseif url:match "miro%.com" then
    link_text = "miro"
  elseif url:match "slack%.com" then
    link_text = "slack"
  else
    -- Extract domain name without TLD extension for default case
    local domain = url:match "https?://([^/]+)"
    if domain then
      -- Remove www. prefix if present
      domain = domain:gsub("^www%.", "")
      -- Extract the main domain name (before the TLD)
      local domain_name = domain:match "([^%.]+)"
      if domain_name then
        link_text = domain_name
      end
    end
  end

  return link_text
end

M.smart_link_paste = function()
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

  local link_text = get_link_text(clipboard_content)
  local markdown_link = string.format("[%s](%s)", link_text, clipboard_content)

  -- Insert at cursor position (like 'p' - after cursor)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_line = vim.api.nvim_get_current_line()
  local col = cursor_pos[2]

  -- Split the line at cursor position and insert the link
  local before = current_line:sub(1, col)
  local after = current_line:sub(col + 1)
  local new_line = before .. " " .. markdown_link .. after

  vim.api.nvim_set_current_line(new_line)

  -- Move cursor to end of inserted link
  vim.api.nvim_win_set_cursor(0, { cursor_pos[1], col + 1 + #markdown_link })
end

M.smart_link_paste_before = function()
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

  local link_text = get_link_text(clipboard_content)
  local markdown_link = string.format("[%s](%s)", link_text, clipboard_content)

  -- Insert before cursor position (like 'P' - before cursor)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_line = vim.api.nvim_get_current_line()
  local col = cursor_pos[2]

  -- Split the line at cursor position and insert the link before
  local before = current_line:sub(1, col)
  local after = current_line:sub(col + 1)
  local new_line = before .. markdown_link .. " " .. after

  vim.api.nvim_set_current_line(new_line)

  -- Move cursor to end of inserted link
  vim.api.nvim_win_set_cursor(0, { cursor_pos[1], col + #markdown_link })
end

return M
