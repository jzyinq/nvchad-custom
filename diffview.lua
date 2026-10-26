-- Helpers for diffing the working tree against another branch.
-- Used by the <leader>g* mappings in custom.mappings.

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Diffview" })
end

local function in_git_repo()
  vim.fn.system { "git", "rev-parse", "--is-inside-work-tree" }
  if vim.v.shell_error ~= 0 then
    notify("Not inside a git repository", vim.log.levels.WARN)
    return false
  end
  return true
end

-- All local and remote branch names, upstream of HEAD first.
function M.branches()
  -- List form keeps the args away from the shell: `%(refname:short)` would
  -- otherwise be mangled by zsh.
  local out = vim.fn.systemlist { "git", "for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/remotes" }
  if vim.v.shell_error ~= 0 then
    return {}
  end

  -- refs/remotes also yields the bare remote names themselves; drop those.
  local skip = {}
  for _, remote in ipairs(vim.fn.systemlist { "git", "remote" }) do
    skip[remote] = true
    skip[remote .. "/HEAD"] = true
  end

  local upstream = vim.fn.systemlist { "git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}" }
  if vim.v.shell_error == 0 and upstream[1] then
    table.insert(out, 1, upstream[1])
  end

  local seen, branches = {}, {}
  for _, name in ipairs(out) do
    if name ~= "" and not skip[name] and not seen[name] then
      seen[name] = true
      branches[#branches + 1] = name
    end
  end
  return branches
end

-- Completion callback for the vim.ui.input prompts below.
function M.complete_branch(arg_lead)
  return vim.tbl_filter(function(name)
    return name:find(arg_lead, 1, true) == 1
  end, M.branches())
end

_G.__diffview_complete_branch = M.complete_branch

local function prompt_branch(prompt, on_confirm)
  if not in_git_repo() then
    return
  end
  vim.ui.input({
    prompt = prompt,
    default = M.branches()[1] or "",
    completion = "customlist,v:lua.__diffview_complete_branch",
  }, function(input)
    if input and input ~= "" then
      on_confirm(vim.trim(input))
    end
  end)
end

-- Diff the working tree against the merge base with `branch` (the "PR diff").
function M.open_against_branch()
  prompt_branch("Diff against branch: ", function(branch)
    vim.cmd("DiffviewOpen " .. vim.fn.fnameescape(branch) .. "...HEAD --imply-local")
  end)
end

-- Point gitsigns' signs/hunks at `branch` instead of the index.
function M.set_gitsigns_base()
  local ok, gitsigns = pcall(require, "gitsigns")
  if not ok then
    notify("gitsigns is not available", vim.log.levels.WARN)
    return
  end

  prompt_branch("Gitsigns base: ", function(branch)
    gitsigns.change_base(branch, true)
    notify("Gitsigns base set to " .. branch)
  end)
end

function M.reset_gitsigns_base()
  local ok, gitsigns = pcall(require, "gitsigns")
  if not ok then
    notify("gitsigns is not available", vim.log.levels.WARN)
    return
  end
  gitsigns.change_base(nil, true)
  notify "Gitsigns base reset to index"
end

return M
