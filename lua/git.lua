local CommitView = require("views.commit")
local Helper = require("utils.init")

local M = {}

M.setup = function ()
    M.is_active_repo = M.check_if_repo()
end
--------------------
-- Init
--------------------
M.init = function(_)
    local result = Helper.execute_shell("git init")
    return result
end
M.check_if_repo = function(_)
    local result = Helper.execute_shell("git rev-parse --is-inside-work-tree")
    if result then
        return result:match("^true") ~= nil
    end
    return false
end


--------------------
-- Status
--------------------
M.status = function(_)
    local result = Helper.execute_shell("git status")
    if result and #result > 0 then
        result = result:gsub("%s*%b()", "")
    end
    M.last_cmd = M.status
    return result
end
M.show_status = function(_)
    local r = M.status()
    Helper.print_to_buffer(r)
end


--------------------
-- Adding
--------------------
M.add_file = function(args)
    args = args or {}
    if args.file then
        local result = Helper.execute_shell("git add " .. args.file)
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
M.add_all = function(_)
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
M.commit_all = function(_)
    CommitView.show({prompt = "Commit Message:"})
end


--------------------
-- Pushing
--------------------
M.push = function(_)
    local result = Helper.execute_shell("git push", true)
    return result
end

M.remote_add = function(_)
    CommitView.show({prompt = "Remote URL:", git_cmd = "git remote add %s"})
end

--------------------
-- Untracking
--------------------
M.untrack_file = function(args)
    args = args or {}
    if args.file then
        local result = Helper.execute_shell("git reset " .. args.file)
        if result and string.find(result, "error") then
            return result
        end
    end
    return false
end
M.untrack_all = function(_)
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
-- Branching
--------------------
M.branches = function(_)
    local branches = M.get_branches()
    local lines = {}
    for branch, props in pairs(branches) do
        local upstream_set = not props.upstream and "x" or ""
        table.insert(lines, string.format("%-2s%-2s%s", props.raw_active, upstream_set, branch))
    end
    Helper.print_to_buffer(lines)
end
M.branch_action = function (args)
    args = args or {
        git_cmd = "git merge %s"
    }
    local lines = vim.api.nvim_buf_get_lines(Helper.buf, 0, -1, false)
    local _, line = vim.api.nvim_get_current_line():match("(%**)%s*(.*)")
    local active_branch = nil
    for _, l in ipairs(lines) do
        local active, branch_name = l:match("%s*(%*)%s*(.*)")
        if active then
            active_branch = branch_name
        end
    end
    if active_branch and active_branch ~= line then
        local cmd = string.format(args.git_cmd, line)
        return Helper.execute_shell(cmd)
    end
    return false
end
M.get_branches = function(_)
    local branches_raw = Helper.execute_shell('git for-each-ref --format="%(HEAD) %(refname:short) %(upstream:short)" refs/heads')
    local branches = {}
    if branches_raw then
        branches_raw = vim.fn.split(branches_raw, "\n")
        for _, branch in ipairs(branches_raw) do
            print(branch)
            local active, name, upstream  = branch:match("(%**)%s*(%S+)%s*(%S*)%c?$")
            branches[name] = {is_active = (active == "*"), upstream = upstream, raw_active = active or "",}
        end
    end
    return branches
end


return M
