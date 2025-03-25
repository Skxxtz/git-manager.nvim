local CommitView = require("views.commit")
local Messages = require("messages")
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
    Helper.execute_shell("git add .")
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
        local result, exit_code = Helper.execute_shell("git reset " .. args.file)
        if exit_code ~= 0 then
            return result
        end
    end
    return false
end
M.untrack_all = function(_)
    local result, exit_code = Helper.execute_shell("git reset")
    if exit_code ~= 0 then
        return result
    end
    return false
end


--------------------
-- Branching
--------------------
M.branch = function(_)
    local branches = M.get_branches()
    local lines = {}
    local upstream_lines = {}
    for branch, props in pairs(branches) do
        if props.upstream == "" then
            table.insert(upstream_lines, #lines)
        end
        table.insert(lines, string.format("%-2s%s", props.raw_active, branch))
    end
    Helper.print_to_buffer(lines)

    for _, index in ipairs(upstream_lines) do
        vim.api.nvim_buf_add_highlight(Helper.buf, Helper.ns_id, "Warning", index, 2, -1  )
    end
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
            local active, name, upstream  = branch:match("(%**)%s+(%S+)%s*(%S*)%c?$")
            branches[name] = {is_active = (active == "*"), upstream = upstream, raw_active = active or "",}
        end
    end
    M.branches = branches
    return branches
end
M.create_branch_on_remote = function(_)
    local remote, _= Helper.execute_shell("git remote")

    if remote ~= "" then
        local line = vim.api.nvim_get_current_line()
        local _, branch_name = line:match("%s*(%**)%s+(%S*)")
        local branch = M.branches[branch_name]
        if branch then
            local cmd = "git push " .. remote .. " %s"
            local prompt = string.format('Add Branch to "%s":', remote)
            CommitView.show({prompt = prompt, content = branch_name, git_cmd = cmd})
        end
    else
        return Messages.no_remote_set
    end
end
M.set_upstream_branch = function(_)
    local remote, _= Helper.execute_shell("git remote")

    if remote ~= "" then
        local line = vim.api.nvim_get_current_line()
        local _, branch_name = line:match("%s*(%**)%s+(%S*)")
        local branch = M.branches[branch_name]
        if branch then
            local content = branch.upstream
            if branch.upstream == "" then
                content = string.format("%s/%s", remote, branch_name)
            end
            local cmd = "git branch -u %s " .. branch_name
            CommitView.show({prompt = "Branch Upstream:", content = content, git_cmd = cmd})
        end
    end
end



return M
