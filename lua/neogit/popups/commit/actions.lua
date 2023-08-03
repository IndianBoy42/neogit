local M = {}

local CommitSelectViewBuffer = require("neogit.buffers.commit_select_view")
local git = require("neogit.lib.git")
local client = require("neogit.client")
local input = require("neogit.lib.input")
local a = require("plenary.async")

local function confirm_modifications()
  if
    git.branch.upstream()
    and #git.repo.upstream.unmerged.items < 1
    and not input.get_confirmation(
      string.format(
        "This commit has already been published to %s, do you really want to modify it?",
        git.branch.upstream()
      ),
      { values = { "&Yes", "&No" }, default = 2 }
    )
  then
    return false
  end

  return true
end

local function do_commit(popup, cmd)
  client.wrap(cmd.arg_list(popup:get_arguments()), {
    autocmd = "NeogitCommitComplete",
    msg = {
      setup = "Committing...",
    },
  })
end

local function commit_special(popup, method)
  local commit = CommitSelectViewBuffer.new(git.log.list()):open_async()
  if not commit then
    return
  end

  a.util.scheduler()
  do_commit(popup, git.cli.commit.args(method, commit))
  a.util.scheduler()

  return commit
end

function M.commit(popup)
  do_commit(popup, git.cli.commit)
end

function M.extend(popup)
  if not confirm_modifications() then
    return
  end

  do_commit(popup, git.cli.commit.no_edit.amend)
end

function M.reword(popup)
  if not confirm_modifications() then
    return
  end

  do_commit(popup, git.cli.commit.amend.only)
end

function M.amend(popup)
  if not confirm_modifications() then
    return
  end

  do_commit(popup, git.cli.commit.amend)
end

function M.fixup(popup)
  commit_special(popup, "--fixup")
end

function M.squash(popup)
  commit_special(popup, "--squash")
end

function M.instant_fixup(popup)
  local commit = commit_special(popup, "--fixup")
  if not commit then
    return
  end

  git.rebase.rebase_interactive(commit .. "~1", "--autosquash")
end

function M.instant_squash(popup)
  local commit = commit_special(popup, "--squash")
  if not commit then
    return
  end

  git.rebase.rebase_interactive(commit .. "~1", "--autosquash")
end

return M
