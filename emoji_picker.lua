-- Telescope emoji picker reusing cmp-emoji's emoji list.
--   <CR>  copy emoji to the system clipboard (+ register)
--   <C-e> insert emoji at cursor instead
local M = {}

function M.pick()
  local ok, items = pcall(require, "cmp_emoji.items")
  if not ok then
    vim.notify("cmp-emoji not available", vim.log.levels.ERROR)
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  local function selected()
    local entry = action_state.get_selected_entry()
    return entry and entry.value.insertText
  end

  pickers
    .new({}, {
      prompt_title = "Emoji",
      finder = finders.new_table {
        results = items(),
        entry_maker = function(item)
          return {
            value = item,
            display = item.label,
            -- ":thumbsup:" -> "thumbsup" so fuzzy matching works on words
            ordinal = item.word:gsub(":", ""):gsub("_", " "),
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local emoji = selected()
          actions.close(prompt_bufnr)
          if emoji then
            vim.fn.setreg("+", emoji)
            vim.notify("Copied " .. emoji)
          end
        end)
        map({ "i", "n" }, "<C-e>", function()
          local emoji = selected()
          actions.close(prompt_bufnr)
          if emoji then
            vim.api.nvim_put({ emoji }, "c", true, true)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
