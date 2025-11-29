--type KeybindsTable = { [string] = {string | function, string, table?} }
local M = {}

M.search_incomplete_tasks = function()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local previewers = require "telescope.previewers"
  local conf = require("telescope.config").values
  local search_command =
  { "rg", "--vimgrep", [[^\s*- \[ \] .*📅 \d{4}-\d{2}-\d{2}]], "/home/jzy/homecloud/backups/obsidian/piwik" }

  pickers
      .new({}, {
        prompt_title = "Incomplete Tasks",
        finder = finders.new_oneshot_job(search_command, {
          entry_maker = function(entry)
            -- Extract file, line number, column, and text from `rg` output
            local filename, lnum, col, text = entry:match "([^:]+):(%d+):(%d+):(.*)"

            -- Remove "- [ ]" from the beginning of the task text
            local clean_text = text:gsub("^%- %[ %] ", "")

            -- Extract date with emoji (📅 YYYY-MM-DD) from the end of the task text
            local date_with_emoji = clean_text:match "📅 %d%d%d%d%-%d%d%-%d%d$" or ""
            clean_text = clean_text:gsub("📅 %d%d%d%d%-%d%d%-%d%d$", "") -- Remove date from end

            -- Format the display with the date (with emoji) at the beginning
            local display_text = string.format("%s - %s", date_with_emoji, clean_text)

            return {
              value = entry,
              display = display_text,                -- Display date first, then task text
              ordinal = date_with_emoji .. clean_text, -- Use date + task text for sorting
              filename = filename,                   -- File path for previewer
              lnum = tonumber(lnum),                 -- Line number for previewer
              col = tonumber(col),                   -- Column (optional)
              text = clean_text,                     -- Clean task text
              date = date_with_emoji,                -- Date with emoji for sorting
            }
          end,
        }),
        sorter = conf.generic_sorter {},
        previewer = previewers.vim_buffer_cat.new {
          define_preview = function(self, entry, status)
            -- Open the file and jump to the specific line for preview
            conf.buffer_previewer_maker(entry.filename, self.state.bufnr, {
              bufname = self.state.bufname,
              lnum = entry.lnum,
            })
          end,
        },
      })
      :find()
end

M.search_recent_notes = function()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local previewers = require "telescope.previewers"
  local conf = require("telescope.config").values
  local action_state = require "telescope.actions.state"
  local actions = require "telescope.actions"

  -- Calculate date 2 weeks ago (14 days)
  local two_weeks_ago = os.time() - (14 * 24 * 60 * 60)

  -- Find all markdown files in the daily folder
  local daily_path = "/home/jzy/homecloud/backups/obsidian/piwik/daily"
  local find_command = "find '" .. daily_path .. "' -type f -name '*.md'"

  -- Get all markdown files
  local handle = io.popen(find_command)
  local result = handle:read("*a")
  handle:close()

  local files = {}
  for file in result:gmatch("[^\r\n]+") do
    -- Get file modification time
    local stat = vim.loop.fs_stat(file)
    if stat and stat.mtime.sec >= two_weeks_ago then
      table.insert(files, {
        path = file,
        mtime = stat.mtime.sec,
      })
    end
  end

  -- Sort files by modification time (newest first)
  table.sort(files, function(a, b)
    return a.mtime > b.mtime
  end)

  -- Create entries for telescope
  local entries = {}
  for _, file in ipairs(files) do
    local filename = file.path:match("^.+/(.+)$")
    local display_name = filename:gsub("%.md$", "")
    local date_str = os.date("%Y-%m-%d %H:%M", file.mtime)

    table.insert(entries, {
      value = file.path,
      display = string.format("%s  [modified: %s]", display_name, date_str),
      ordinal = display_name,
      filename = file.path,
      mtime = file.mtime,
    })
  end

  pickers
      .new({}, {
        prompt_title = "Daily Notes (Last 2 Weeks)",
        finder = finders.new_table {
          results = entries,
          entry_maker = function(entry)
            return entry
          end,
        },
        sorter = conf.generic_sorter {},
        previewer = previewers.vim_buffer_cat.new {},
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            vim.cmd("edit " .. selection.filename)
          end)
          return true
        end,
      })
      :find()
end

M._add_checkbox = function(character, line_num)
	local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

	local checkbox_pattern = "^%s*- %[.] "
	local checkbox = character or " "

	if not string.match(line, checkbox_pattern) then
		local unordered_list_pattern = "^(%s*)[-*+] (.*)"
		if string.match(line, unordered_list_pattern) then
			line = string.gsub(line, unordered_list_pattern, "%1- [ ] %2")
		else
			line = string.gsub(line, "^(%s*)", "%1- [ ] ")
		end
	end
	local capturing_checkbox_pattern = "^(%s*- %[).(%] )"
	line = string.gsub(line, capturing_checkbox_pattern, "%1" .. checkbox .. "%2")

	-- 0-indexed
	vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, true, { line })
end

M._remove_checkbox = function(line_num)
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  local checkbox_pattern = "^%s*- %[.]. "
  local capturing_checkbox_pattern = "^(%s*-) %[.%] (.*)"
  line = string.gsub(line, capturing_checkbox_pattern, "%1 %2")
  line = string.gsub(line, checkbox_pattern, "")
  -- 0-indexed
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, true, { line })
end

M.toggle_checkbox = function(character)
  -- Check if we are in visual line mode
  local mode = vim.api.nvim_get_mode().mode

  local toggle_or_remove = function(character, line_num)
    if character == nil then
      -- Remove checkbox
      M._remove_checkbox(line_num)
    else
      -- Add checkbox
      M._add_checkbox(character, line_num)
    end
  end

  if mode == "V" or mode == "v" then
    -- Get the range of selected lines
    vim.cmd [[execute "normal! \<ESC>"]]
    local vstart = vim.fn.getcharpos "'<"
    local vend = vim.fn.getcharpos "'>"

    local line_start = vstart[2]
    local line_end = vend[2]

    -- Iterate over each line in the range and apply the transformation
    for line_num = line_start, line_end do
      toggle_or_remove(character, line_num)
    end
  else
    -- Normal mode
    -- Allow line_num to be optional, defaulting to the current line if not provided (normal mode)
    local line_num = unpack(vim.api.nvim_win_get_cursor(0))
    toggle_or_remove(character, line_num)
  end
end

return M
