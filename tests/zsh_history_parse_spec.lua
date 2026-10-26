local repo_root = vim.fn.getcwd()
local zsh_history = dofile(repo_root .. "/zsh_history.lua")

local function assert_equal(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s\nexpected: %s\nactual: %s", label, expected, tostring(actual)))
  end
end

local commands = zsh_history.parse(table.concat({
  ": 1727859373:0;git remote rename origin old-origin\\",
  "git remote add origin x\\",
  "",
  ": 1727859400:0;ls -l",
  "plain command",
  ": 1727859500:0;ls -l",
  ": 1731008305:0;ag \"\240\131\191\131\179\131\165\"",
  ": 1731008306:0;   ",
}, "\n"))

assert_equal(#commands, 4, "dedupes and drops empty commands")
assert_equal(commands[1], 'ag "📅"', "unmetafies multibyte characters")
assert_equal(commands[2], "ls -l", "most recent first, deduplicated")
assert_equal(commands[3], "plain command", "keeps non-extended lines")
assert_equal(commands[4], "git remote rename origin old-origin\ngit remote add origin x", "joins multi-line entries")

local function joined(cmd)
  return table.concat(zsh_history.wrap(cmd), "\n")
end

assert_equal(joined "ls -l", "`ls -l`", "wraps single line in backticks")
assert_equal(joined "echo `date`", "`` echo `date` ``", "grows and pads inline span around backticks")
assert_equal(joined "a\nb", "```\na\nb\n```", "wraps multi-line in a fence")
assert_equal(joined "a\n```b", "````\na\n```b\n````", "grows fence past inner backticks")

print "zsh_history_parse_spec: ok"
