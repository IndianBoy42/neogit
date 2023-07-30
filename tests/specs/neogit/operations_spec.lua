require("plenary.async").tests.add_to_env()
local eq = assert.are.same
local operations = require("neogit.operations")
local harness = require("tests.util.git_harness")
local in_prepared_repo = harness.in_prepared_repo
local get_current_branch = harness.get_current_branch
local get_git_branches = harness.get_git_branches
local get_git_rev = harness.get_git_rev
local util = require("tests.util.util")

local FuzzyFinderBuffer = require("tests.mocks.fuzzy_finder")
local status = require("neogit.status")
local input = require("tests.mocks.input")

local function act(normal_cmd)
  print("Feeding keys: ", normal_cmd)
  vim.fn.feedkeys(vim.api.nvim_replace_termcodes(normal_cmd, true, true, true))
  vim.fn.feedkeys("", "x") -- flush typeahead
  status.wait_on_current_operation()
end

describe("branch popup", function()
  it(
    "can switch to another branch in the repository",
    in_prepared_repo(function()
      FuzzyFinderBuffer.value = "second-branch"
      act("bb<cr>")
      operations.wait("checkout_branch_revision")
      eq("second-branch", get_current_branch())
    end)
  )

  it(
    "can switch to another local branch in the repository",
    in_prepared_repo(function()
      FuzzyFinderBuffer.value = "second-branch"
      act("bl<cr>")
      operations.wait("checkout_branch_local")
      eq("second-branch", get_current_branch())
    end)
  )

  it(
    "can create a new branch",
    in_prepared_repo(function()
      input.value = "branch-from-test"
      act("bc<cr><cr>")
      operations.wait("checkout_create_branch")
      eq("branch-from-test", get_current_branch())
    end)
  )

  it(
    "can create a new branch without checking it out",
    in_prepared_repo(function()
      input.value = "branch-from-test-create"
      act("bn<cr><cr>")
      operations.wait("create_branch")
      eq("master", get_current_branch())
      assert.True(vim.tbl_contains(get_git_branches(), "branch-from-test-create"))
    end)
  )

  it(
    "can rename a branch",
    in_prepared_repo(function()
      FuzzyFinderBuffer.value = "second-branch"
      input.value = "second-branch-renamed"

      assert.True(vim.tbl_contains(get_git_branches(), "second-branch"))
      act("bm<cr><cr>")
      operations.wait("rename_branch")
      assert.True(vim.tbl_contains(get_git_branches(), "second-branch-renamed"))
      assert.False(vim.tbl_contains(get_git_branches(), "second-branch"))
    end)
  )

  it(
    "can reset a branch",
    in_prepared_repo(function()
      util.system([[
        git config user.email "test@neogit-test.test"
        git config user.name "Neogit Test"
        ]])

      FuzzyFinderBuffer.value = "second-branch"

      util.system("git commit --allow-empty -m 'test'")
      assert.are.Not.same("e2c2a1c0e5858a690c1dc13edc1fd5de103409d9", get_git_rev("HEAD"))

      act("bXy<cr>")
      operations.wait("reset_branch")
      assert.are.same("e2c2a1c0e5858a690c1dc13edc1fd5de103409d9", get_git_rev("HEAD"))
      assert.are.same('e2c2a1c HEAD@{0}: "reset: moving to second-branch"\n', util.system("git reflog -n1"))
    end)
  )

  it(
    "can delete a branch",
    in_prepared_repo(function()
      FuzzyFinderBuffer.value = "second-branch"

      assert.True(vim.tbl_contains(get_git_branches(), "second-branch"))

      act("bD<cr>")
      operations.wait("delete_branch")
      assert.False(vim.tbl_contains(get_git_branches(), "second-branch"))
    end)
  )
end)
