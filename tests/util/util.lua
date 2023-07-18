local M = {}

M.project_dir = vim.fn.getcwd()

---Returns the path to the raw test files directory
---@return string The path to the project directory
function M.get_test_files_dir()
  return M.project_dir .. "/tests/test_files/"
end

---Runs a system command and errors if it fails
---@param cmd string | table Command to be ran
---@param ignore_err boolean? Whether the error should be ignored
---@param error_msg string? The error message to be emitted on command failure
---@return string The output of the system command
function M.system(cmd, ignore_err, error_msg)
  if ignore_err == nil then
    ignore_err = false
  end

  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 and not ignore_err then
    error(error_msg or ("Command failed: ↓\n" .. cmd .. "\nOutput from command: ↓\n" .. output))
  end
  return output
end

M.neogit_test_base_dir = "/tmp/neogit-testing/"

---Create a temporary directory for use
---@param suffix string? The suffix to be appended to the temp directory, ideally avoid spaces in your suffix
---@return string The path to the temporary directory
function M.create_temp_dir(suffix)
  if suffix == nil then
    suffix = ""
  else
    suffix = "-" .. suffix
  end

  if not vim.loop.fs_stat("/tmp/neogit-testing") then
    M.system("mkdir " .. M.neogit_test_base_dir)
  end
  local tmp_dir =
    vim.trim(M.system(string.format("mktemp -d --suffix=%s -p %s", suffix, M.neogit_test_base_dir)))
  return tmp_dir
end

return M
