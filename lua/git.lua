local CommitView = require("views.commit")
local BranchView = require("views.branch")
local Binds = require("binds")
local Helper = require("utils.init")

local M = {}


--------------------
-- Init
--------------------
M.init = function()
    local result = Helper.execute_shell("git init")
    Binds.set_binds(Binds.binds.defaults)
    return result
end
M.is_active_repo = function()
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
    Binds.set_binds(Binds.binds.defaults)
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
    Binds.set_binds(Binds.binds.defaults)
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
M.add_all = function()
    Binds.set_binds(Binds.binds.defaults)
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
    Binds.set_binds(Binds.binds.commit_view)

    CommitView.prompt = "Commit Message:"
    CommitView.prompt = vim.fn.split(CommitView.prompt, "\n")

    vim.api.nvim_buf_set_lines(Helper.buf, 0, -1, false, CommitView.prompt)
    vim.api.nvim_win_set_cursor(Helper.win, { #CommitView.prompt, 0 })
end


--------------------
-- Pushing
--------------------
M.push = function()
    Binds.set_binds(Binds.binds.defaults)
    local result = Helper.execute_shell("git push", true)
    return result
end

M.push_all = function()
    Binds.set_binds(Binds.binds.push_view)

    CommitView.prompt = "Remote URL:"
    CommitView.prompt = vim.fn.split(CommitView.prompt, "\n")

    vim.api.nvim_buf_set_lines(Helper.buf, 0, -1, false, CommitView.prompt)
    vim.api.nvim_win_set_cursor(Helper.win, { #CommitView.prompt, 0 })
end

--------------------
-- Untracking
--------------------
M.untrack_file = function(file)
    Binds.set_binds(Binds.binds.defaults)
    local result = Helper.execute_shell("git reset " .. file)
    return result
end
M.untrack_all = function()
    Binds.set_binds(Binds.binds.defaults)
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
    Binds.set_binds(Binds.binds.branch_view)
    local branches = M.get_branches()
    Helper.print_to_buffer(branches)
end
M.get_branches = function()
    local branches_raw = Helper.execute_shell("git branch")
    if branches_raw then
        branches_raw = vim.fn.split(branches_raw, "\n")
        return branches_raw
    end
end

Binds.is_active_repo = M.is_active_repo()
Binds.binds = {
    commit_view = {
        { mode = "n", map = "<C-CR>", callback = Binds.status_op, nested = CommitView.accept, after = M.show_status, args={git_cmd = "Git commit -m "}},
        { mode = "n", map = "<UP>",   callback = Binds.status_op, nested = CommitView.next_cached },
        { mode = "n", map = "<DOWN>", callback = Binds.status_op, nested = CommitView.prev_cached },

    },
    push_view = {
        { mode = "n", map = "<C-CR>", callback = Binds.status_op, nested = CommitView.accept, after = M.show_status, args={git_cmd = ""}},

    },
    branch_view = {
        { mode = "n", map = "r", action = "<Nop>" },
        { mode = "n", map = "r", callback = Binds.status_op, nested = BranchView.rename },

        { mode = "n", map = "o", action = "<Nop>" },
        { mode = "n", map = "o", callback = Binds.status_op, nested = BranchView.add },

        { mode = "n", map = "<C-d>", action = "<Nop>" },
        { mode = "n", map = "<C-d>", callback = Binds.status_op, nested = BranchView.delete, after = M.switch, args={file = true}},

        { mode = "n", map = "<CR>", callback = Binds.status_op, nested = BranchView.switch, after = M.switch,   args={file = true} },

    },
    defaults = {
        { mode = "n", map = "u",     action = "<Nop>" },
        { mode = "n", map = "u",     callback = Binds.status_op, nested = M.untrack_file, after = M.show_status, args={file = true} },
        { mode = "n", map = "<C-u>", callback = Binds.status_op, nested = M.untrack_all,  after = M.show_status, args={file = true} },

        { mode = "n", map = "a",     action = "<Nop>" },
        { mode = "n", map = "a",     callback = Binds.status_op, nested = M.add_file,     after = M.show_status, args={file = true} },
        { mode = "n", map = "<C-a>", callback = Binds.status_op, nested = M.add_all,      after = M.show_status, args={file = true} },


        { mode = "n", map = "p",     action = "<Nop>" },
        { mode = "n", map = "p",     callback = Binds.status_op, nested = M.push },
    },
    init = {
        { mode = "n", map = "i", action = "<Nop>" },
        { mode = "n", map = "i", callback = M.status_op, nested = M.status, after = M.add_binds },

    },
    always = {
        { mode = "n", map = "S",     action = "<Nop>" },
        { mode = "n", map = "S",     callback = Binds.status_op, nested = M.switch },

        { mode = "n", map = "s",     action = "<Nop>" },
        { mode = "n", map = "s",     callback = Binds.status_op, nested = M.status },

        { mode = "n", map = "<C-c>", action = "<Nop>" },
        { mode = "n", map = "<C-c>", callback = Binds.status_op, nested = M.commit_all },

        { mode = "n", map = "q", action = "<Nop>" },
        { mode = "n", map = "q", callback = Binds.quit },

        { mode = "n", map = "<Esc>", action = "<Nop>" },
        { mode = "n", map = "<Esc>", callback = Binds.quit },
    }
}

return M
