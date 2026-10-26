local M = {}

local HISTFILE = vim.env.HISTFILE or (vim.env.HOME .. "/.zsh_history")

-- zsh "metafies" bytes >= 0x83 on disk: Meta (0x83) followed by byte XOR 0x20
local function unmetafy(s)
  return (s:gsub("\131(.)", function(c)
    return string.char(bit.bxor(c:byte(), 32))
  end))
end

-- Returns unique commands, most recent first. Handles EXTENDED_HISTORY
-- (": <ts>:<duration>;<cmd>") and multi-line entries, where zsh writes each
-- embedded newline as a trailing backslash on the physical line.
M.parse = function(content)
  local entries = {}
  local current

  for line in (content .. "\n"):gmatch "(.-)\r?\n" do
    if current then
      table.insert(current, line)
    else
      current = { line:match "^: %d+:%d+;(.*)$" or line }
    end

    if current[#current]:sub(-1) == "\\" then
      current[#current] = current[#current]:sub(1, -2)
    else
      local cmd = vim.trim(unmetafy(table.concat(current, "\n")))
      if cmd ~= "" then
        table.insert(entries, cmd)
      end
      current = nil
    end
  end

  local seen, commands = {}, {}
  for i = #entries, 1, -1 do
    if not seen[entries[i]] then
      seen[entries[i]] = true
      table.insert(commands, entries[i])
    end
  end
  return commands
end

local function longest_backtick_run(s)
  local longest = 0
  for run in s:gmatch "`+" do
    longest = math.max(longest, #run)
  end
  return longest
end

-- Wraps a command as Markdown code: inline span for one line, fenced block
-- otherwise. Delimiters grow past any backtick run inside the command.
M.wrap = function(cmd)
  local lines = vim.split(cmd, "\n")
  local longest = longest_backtick_run(cmd)
  if #lines == 1 then
    local ticks = string.rep("`", longest + 1)
    local pad = (cmd:sub(1, 1) == "`" or cmd:sub(-1) == "`") and " " or ""
    return { ticks .. pad .. cmd .. pad .. ticks }
  end
  local fence = string.rep("`", math.max(3, longest + 1))
  table.insert(lines, 1, fence)
  table.insert(lines, fence)
  return lines
end

M.search = function()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local previewers = require "telescope.previewers"
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local conf = require("telescope.config").values

  local file = io.open(HISTFILE, "rb")
  if not file then
    vim.notify("Cannot read " .. HISTFILE, vim.log.levels.ERROR)
    return
  end
  local commands = M.parse(file:read "*a")
  file:close()

  pickers
    .new({}, {
      prompt_title = "Zsh History",
      finder = finders.new_table {
        results = commands,
        entry_maker = function(cmd)
          local display = cmd:gsub("\n", " ↵ ")
          return { value = cmd, display = display, ordinal = display }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        title = "Command",
        define_preview = function(self, entry)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.value, "\n"))
          vim.bo[self.state.bufnr].filetype = "zsh"
        end,
      },
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry then
            local lines = M.wrap(entry.value)
            -- a fenced block needs its own lines, so put it below the cursor line
            vim.api.nvim_put(lines, #lines == 1 and "c" or "l", true, true)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
