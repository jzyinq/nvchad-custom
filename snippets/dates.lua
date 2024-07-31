local ls = require "luasnip"
local snippet = ls.snippet
-- get tomorrow date in a format of YYYY-MM-DD
local function get_tomorrow_date()
  local tomorrow = os.time() + 86400
  return os.date("%Y-%m-%d", tomorrow)
end

-- function to get the next occurrence date for a given day abbreviation
local function get_next_day_date(day_abbr)
  local days = {
    mon = 2,
    tue = 3,
    wed = 4,
    thu = 5,
    fri = 6,
    sat = 7,
    sun = 1,
  }

  local target_day = days[day_abbr]

  if target_day == nil then
    return "Invalid day abbreviation"
  end

  local today = os.time()
  local today_day = os.date("*t", today).wday

  -- Calculate the number of days until the target day
  local days_until_target = (target_day - today_day + 7) % 7
  -- If the target day is today, get the next week's occurrence
  if days_until_target == 0 then
    days_until_target = 7
  end

  -- Calculate the date for the next occurring target day
  local next_target_date = os.date("%Y-%m-%d", today + days_until_target * 86400)
  return next_target_date
end

ls.add_snippets("all", {
  snippet("monday", {
    ls.function_node(function()
      return get_next_day_date("mon")
    end), -- Define that this snippet takes one argument
  }),
  snippet("tuesday", {
    ls.function_node(function()
      return get_next_day_date("tue")
    end), -- Define that this snippet takes one argument
  }),
  snippet("wednesday", {
    ls.function_node(function()
      return get_next_day_date("wed")
    end), -- Define that this snippet takes one argument
  }),
  snippet("thursday", {
    ls.function_node(function()
      return get_next_day_date("thu")
    end), -- Define that this snippet takes one argument
  }),
  snippet("friday", {
    ls.function_node(function()
      return get_next_day_date("fri")
    end), -- Define that this snippet takes one argument
  }),
})

ls.add_snippets("all", {
  snippet("tomorrow", {
    ls.function_node(function()
      return get_tomorrow_date()
    end),
  }),
})

ls.add_snippets("markdown", {
  snippet("due", {
    ls.function_node(function()
      return "📅 "
    end),
  }),
})
