local M = {}

M.smart_link_paste = function()
  -- Check if we're in a markdown file
  local filetype = vim.bo.filetype
  if filetype ~= "markdown" and filetype ~= "mdx" then
    vim.notify("Smart link paste only works in markdown files", vim.log.levels.WARN)
    return
  end

  -- Get clipboard content
  local clipboard_content = vim.fn.getreg "+"
  if not clipboard_content or clipboard_content == "" then
    vim.notify("No URL in clipboard detected", vim.log.levels.WARN)
    return
  end

  -- Clean the clipboard content (remove whitespace)
  clipboard_content = clipboard_content:gsub("^%s*(.-)%s*$", "%1")

  -- Basic URL validation
  if not clipboard_content:match "^https?://" then
    vim.notify("No valid URL in clipboard detected", vim.log.levels.WARN)
    return
  end

  -- Determine link text based on URL domain/path
  local link_text = "web" -- default

  if clipboard_content:match "github%.com/[^/]+/[^/]+/issues/" then
    link_text = "github-issue"
  elseif clipboard_content:match "github%.com/[^/]+/[^/]+/pull/" then
    link_text = "github-pr"
  elseif clipboard_content:match "github%.com/[^/]+/[^/]+/actions" then
    link_text = "github-actions"
  elseif clipboard_content:match "github%.com/[^/]+/[^/]+/releases" then
    link_text = "github-releases"
  elseif clipboard_content:match "github%.com/[^/]+/[^/]+/?$" then
    link_text = "github-repo"
  elseif clipboard_content:match "github%.com" then
    link_text = "github"
  elseif clipboard_content:match "atlassian%.net/wiki/" then
    link_text = "confluence"
  elseif clipboard_content:match "atlassian%.net/browse/" then
    link_text = "jira"
  elseif clipboard_content:match "miro%.com" then
    link_text = "miro"
  elseif clipboard_content:match "slack%.com" then
    link_text = "slack"
  else
    -- Extract domain name without TLD extension for default case
    local domain = clipboard_content:match "https?://([^/]+)"
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

  -- Create markdown link
  local markdown_link = string.format("[%s](%s)", link_text, clipboard_content)

  -- Insert at cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local current_line = vim.api.nvim_get_current_line()
  local col = cursor_pos[2]

  -- Split the line at cursor position and insert the link
  local before = current_line:sub(1, col)
  local after = current_line:sub(col + 1)
  local new_line = before .. " " .. markdown_link .. after

  vim.api.nvim_set_current_line(new_line)

  -- Move cursor to end of inserted link
  vim.api.nvim_win_set_cursor(0, { cursor_pos[1], col + #markdown_link })
end

return M
