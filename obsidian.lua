--type KeybindsTable = { [string] = {string | function, string, table?} }
local M = {}

local TASK_SEARCH_PATHS = {
  "/home/jzy/homecloud/backups/obsidian/piwik/daily",
  "/home/jzy/homecloud/backups/obsidian/piwik/projects",
}

M.search_incomplete_tasks = function()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local previewers = require "telescope.previewers"
  local conf = require("telescope.config").values

  M.get_tasks_with_dates(function(tasks)
    vim.schedule(function()
      pickers.new({}, {
        prompt_title = "Incomplete Tasks",
        finder = finders.new_table({
          results = tasks,
          entry_maker = function(task)
            local clean_text = task.text:gsub("^%- %[ %] ", "")
            local date_with_emoji = "📅 " .. task.date
            clean_text = clean_text:gsub("📅 %d%d%d%d%-%d%d%-%d%d$", "")

            return {
              value = task,
              display = string.format("%s - %s", date_with_emoji, clean_text),
              ordinal = task.date .. clean_text,
              filename = task.filename,
              lnum = task.lnum,
              col = task.col,
            }
          end,
        }),
        sorter = conf.generic_sorter {},
        previewer = previewers.vim_buffer_cat.new {
          define_preview = function(self, entry)
            conf.buffer_previewer_maker(entry.filename, self.state.bufnr, {
              bufname = self.state.bufname,
              lnum = entry.lnum,
            })
          end,
        },
      }):find()
    end)
  end)
end

M.search_overdue_tasks = function()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local previewers = require "telescope.previewers"
  local conf = require("telescope.config").values

  M.get_overdue_tasks(function(tasks)
    vim.schedule(function()
      pickers.new({}, {
        prompt_title = "Overdue Tasks",
        finder = finders.new_table({
          results = tasks,
          entry_maker = function(task)
            local clean_text = task.text:gsub("^%- %[ %] ", "")
            local date_with_emoji = "📅 " .. task.date
            clean_text = clean_text:gsub("📅 %d%d%d%d%-%d%d%-%d%d$", "")

            return {
              value = task,
              display = string.format("%s - %s", date_with_emoji, clean_text),
              ordinal = task.date .. clean_text,
              filename = task.filename,
              lnum = task.lnum,
              col = task.col,
            }
          end,
        }),
        sorter = conf.generic_sorter {},
        previewer = previewers.vim_buffer_cat.new {
          define_preview = function(self, entry)
            conf.buffer_previewer_maker(entry.filename, self.state.bufnr, {
              bufname = self.state.bufname,
              lnum = entry.lnum,
            })
          end,
        },
      }):find()
    end)
  end)
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

-- Overdue tasks indicator
local overdue_ns = vim.api.nvim_create_namespace("obsidian_overdue_indicator")
local overdue_indicator_initialized = false

M.is_today_note = function(filepath)
  local today = os.date("%Y-%m-%d")
  local filename = filepath:match("([^/]+)%.md$")
  return filename == today
end

M.get_tasks_with_dates = function(callback, filter_fn)
  local today = os.date("%Y-%m-%d")
  local cmd = vim.list_extend(
    { "rg", "--vimgrep", [[^\s*- \[ \] .*📅 \d{4}-\d{2}-\d{2}]] },
    TASK_SEARCH_PATHS
  )

  local tasks = {}
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then
          local filename, lnum, col, text = line:match("([^:]+):(%d+):(%d+):(.*)")
          if filename then
            local task_date = text:match("📅 (%d%d%d%d%-%d%d%-%d%d)")
            if task_date then
              local include = true
              if filter_fn then
                include = filter_fn(task_date, today)
              end
              if include then
                table.insert(tasks, {
                  filename = filename,
                  lnum = tonumber(lnum),
                  col = tonumber(col),
                  text = text,
                  date = task_date,
                })
              end
            end
          end
        end
      end
    end,
    on_exit = function()
      -- Sort by date chronologically
      table.sort(tasks, function(a, b)
        return a.date < b.date
      end)
      callback(tasks)
    end,
  })
end

M.get_overdue_tasks = function(callback)
  M.get_tasks_with_dates(callback, function(task_date, today)
    return task_date <= today
  end)
end

M.count_overdue_tasks = function(callback)
  M.get_overdue_tasks(function(tasks)
    callback(#tasks)
  end)
end

M.show_overdue_indicator = function()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)

  -- Clear existing extmarks
  vim.api.nvim_buf_clear_namespace(buf, overdue_ns, 0, -1)

  -- Only show for today's note
  if not M.is_today_note(filepath) then
    return
  end

  M.get_overdue_tasks(function(tasks)
    vim.schedule(function()
      -- Check if buffer is still valid
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      if #tasks == 0 then
        return
      end

      -- Find closing --- of YAML frontmatter
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local frontmatter_end = 0
      local found_start = false
      for i, line in ipairs(lines) do
        if line:match("^%-%-%-$") then
          if found_start then
            frontmatter_end = i - 1  -- 0-indexed
            break
          else
            found_start = true
          end
        end
      end

      -- Build virtual lines with task list
      local virt_lines = {
        { { string.format("⚠ %d overdue task%s:", #tasks, #tasks > 1 and "s" or ""), "WarningMsg" } },
      }

      for _, task in ipairs(tasks) do
        local clean_text = task.text:gsub("^%- %[ %] ", "")
        clean_text = clean_text:gsub("📅 %d%d%d%d%-%d%d%-%d%d$", "")
        local display = string.format("  • [%s] %s", task.date, clean_text)
        table.insert(virt_lines, { { display, "Comment" } })
      end

      table.insert(virt_lines, { { string.format("<leader>to Overdue / <leader>tf All"), "Comment" }} )

      vim.api.nvim_buf_set_extmark(buf, overdue_ns, frontmatter_end, 0, {
        virt_lines = virt_lines,
      })
    end)
  end)
end

M.setup_overdue_indicator = function()
  if overdue_indicator_initialized then
    return
  end
  overdue_indicator_initialized = true

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    pattern = "*.md",
    callback = function()
      M.show_overdue_indicator()
    end,
  })
end

-- Auto-setup when module is loaded
M.setup_overdue_indicator()

return M
