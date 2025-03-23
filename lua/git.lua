local CommitView = require("views.commit")
local Helper = require("utils.init")

local M = {}

M.setup = function ()
    M.is_active_repo = M.check_if_repo()
end
--------------------
-- Init
--------------------
M.init = function()
    local result = Helper.execute_shell("git init")
    return result
end
M.check_if_repo = function()
    local result = Helper.execute_shell("git rev-parse --is-inside-work-tree")
    if result then
        return result:match("^true") ~= nil
    end
    return false
end


--------------------
-- Status
--------------------
M.status = function()
    local result = Helper.execute_shell("git status")
    if result and #result > 0 then
        result = result:gsub("%s*%b()", "")
    end
    M.last_cmd = M.status
    return result
end
M.show_status = function()
    local r = M.status()
    Helper.print_to_buffer(r)
end


--------------------
-- Adding
--------------------
M.add_file = function(file)
    if file then
        local result = Helper.execute_shell("git add " .. file)
        if #result > 0 then
            M.last_cmd = M.add_file
        else
            if M.last_cmd == M.status then
                result = M.last_cmd()
            end
        end
        return result
    end
    return false
end
M.add_all = function()
    local result = Helper.execute_shell("git add .")
    if #result > 0 then
        M.last_cmd = M.add_all
    else
        if M.last_cmd == M.status then
            result = M.last_cmd()
        end
    end
    return result
end


--------------------
-- Committing
--------------------
M.commit_all = function()
    CommitView.show({prompt = "Commit Message:"})
end


--------------------
-- Pushing
--------------------
M.push = function()
    local result = Helper.execute_shell("git push", true)
    return result
end

M.remote_add = function()
    CommitView.show({prompt = "Remote URL:", git_cmd = "git remote add %s"})
end

--------------------
-- Untracking
--------------------
M.untrack_file = function(file)
    if file then
        local result = Helper.execute_shell("git reset " .. file)
        if result and string.find(result, "error") then
            return result
        end
    end
    return false
end
M.untrack_all = function()
    local result = Helper.execute_shell("git reset")
    if #result > 0 then
        M.last_cmd = M.untrack_all
    else
        if M.last_cmd == M.status then
            result = M.last_cmd()
        end
    end
    return result
end


--------------------
-- Switch
--------------------
M.switch = function()
    local branches = M.get_branches()
    Helper.print_to_buffer(branches)
end
M.merge = function ()
    local lines = vim.api.nvim_buf_get_lines(Helper.buf, 0, -1, false)
    local _, line = vim.api.nvim_get_current_line():match("(%**)%s*(.*)")
    local active_branch = nil
    for _, l in ipairs(lines) do
        local active, branch_name = l:match("(%**)%s*(.*)")
        if active then
            active_branch = branch_name
        end
    end
    if active_branch and active_branch ~= line then
        local cmd = string.format("git merge --rebase %s", line)
        Helper.execute_shell(cmd)
    end
end
M.get_branches = function()
    local branches_raw = Helper.execute_shell("git branch")
    if branches_raw then
        branches_raw = vim.fn.split(branches_raw, "\n")
        return branches_raw
    end
end


return M
