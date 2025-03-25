local Messages = require("messages")
local Helper = require("utils.init")
local BranchView = require("views.branch")
local CommitView = require("views.commit")
local Git = require("git")


local M = {
    current_binds = {},
    always_binds = {}
}

M.eval_bind = function(map)
    local result
    if map.new_binds then
        M.set_binds(map.new_binds)
    end

    if map.args and map.args.line then
        local file = Helper.get_file_under_cursor()
        if file then
            map.args.file = file
        end
        result = map.nested(map.args)
    elseif map.args then
        result = map.nested(map.args)
    else
        result = map.nested()
    end

    if map.after and not result then
        if map.after_args then
            map.after(map.after_args)
        else
            map.after()
        end
    else
        Helper.print_to_buffer(result)
    end
end

M.set_binds = function (binds)
    if binds and binds ~= M.bindgroup then
        M.bindgroup = binds
        if not Git.is_active_repo then
            binds = M.binds.init
            Helper.print_to_buffer(Messages.is_no_repo)
        else
            binds = M.binds[binds]
        end

        for map, mode in pairs(M.current_binds) do
            vim.keymap.del(mode, map, {buffer=Helper.buf})
        end
        M.current_binds = {}
        vim.api.nvim_clear_autocmds({group = 'BranchAu'})
        for _, map in ipairs(binds) do
            if map.action then
                vim.keymap.set(map.mode, map.map, map.action, {buffer = Helper.buf})
            else
                vim.keymap.set(map.mode, map.map, function ()
                    map.callback(map)
                end, {buffer = Helper.buf})
                M.current_binds[map.map] = map.mode
            end
        end
        return Git.is_active_repo
    end
    return false
end

M.set_always_binds = function ()
    for _, map in ipairs(M.binds["always"]) do
        if map.action then
            vim.keymap.set(map.mode, map.map, map.action, {buffer = Helper.buf})
        else
            vim.keymap.set(map.mode, map.map, function ()
                map.callback(map)
            end, {buffer = Helper.buf})
            M.always_binds[map.map] = map.mode
        end
    end
end


M.quit = function ()
    if Helper.win and Helper.buf then
        for map, mode in pairs(M.always_binds) do
            vim.keymap.del(mode, map, {buffer=Helper.buf})
        end

        for map, mode in pairs(M.current_binds) do
            vim.keymap.del(mode, map, {buffer=Helper.buf})
        end

        M.current_binds = {}
        M.always_binds = {}
        M.bindgroup = nil

        vim.api.nvim_buf_delete(Helper.buf, {force = true})
        Helper.buf = nil
    end
end


M.binds = {
    ["commit_view"] = {
        { mode = "n", map = "<C-CR>", callback = M.eval_bind, nested = CommitView.accept, after = Git.show_status, args={git_cmd = "Git commit -m "}, new_binds = "defaults"},
        { mode = "n", map = "<UP>",   callback = M.eval_bind, nested = CommitView.next_cached },
        { mode = "n", map = "<DOWN>", callback = M.eval_bind, nested = CommitView.prev_cached },

        { mode = "n", map = "<C-f>", action = "<Nop>" },
        { mode = "n", map = "<C-f>", callback = M.eval_bind, nested = CommitView.show, args={line = true, content = "[frontend] ", prompt = "Commit Message:"}},
        { mode = "n", map = "<C-b>", action = "<Nop>" },
        { mode = "n", map = "<C-b>", callback = M.eval_bind, nested = CommitView.show, args={line = true, content = "[backend] ", prompt = "Commit Message:"}},
    },
    ["remote_add_view"] = {
        { mode = "n", map = "<C-CR>", callback = M.eval_bind, nested = CommitView.accept, after = Git.show_status, new_binds = "defaults"},
    },
    ["branch_view"] = {
        { mode = "n", map = "rn", action = "<Nop>" },
        { mode = "n", map = "rn", callback = M.eval_bind, nested = BranchView.rename },

        { mode = "n", map = "o", action = "<Nop>" },
        { mode = "n", map = "o", callback = M.eval_bind, nested = BranchView.add },

        { mode = "n", map = "m", action = "<Nop>" },
        { mode = "n", map = "m", callback = M.eval_bind, nested = Git.branch_action, args = {git_cmd = "git merge %"}},

        { mode = "n", map = "rb", action = "<Nop>" },
        { mode = "n", map = "rb", callback = M.eval_bind, nested = Git.branch_action, args = {git_cmd = "git rebase %s"}},

        { mode = "n", map = "<C-d>", action = "<Nop>" },
        { mode = "n", map = "<C-d>", callback = M.eval_bind, nested = BranchView.delete, after = Git.branches, args={line = true}},

        { mode = "n", map = "<CR>", callback = M.eval_bind, nested = BranchView.switch, after = Git.branches,   args={line = true} },
    },
    ["defaults"] = {
        { mode = "n", map = "u",     action = "<Nop>" },
        { mode = "n", map = "u",     callback = M.eval_bind, nested = Git.untrack_file, after = Git.show_status, args={line = true} },
        { mode = "n", map = "<C-u>", callback = M.eval_bind, nested = Git.untrack_all,  after = Git.show_status, args={line = true} },

        { mode = "n", map = "a",     action = "<Nop>" },
        { mode = "n", map = "a",     callback = M.eval_bind, nested = Git.add_file,     after = Git.show_status, args={line = true} },
        { mode = "n", map = "<C-a>", callback = M.eval_bind, nested = Git.add_all,      after = Git.show_status, args={line = true} },


        { mode = "n", map = "p",     action = "<Nop>" },
        { mode = "n", map = "p",     callback = M.eval_bind, nested = Git.push },

        { mode = "n", map = "<C-p>r",     action = "<Nop>" },
        { mode = "n", map = "<C-p>r",     callback = M.eval_bind, nested = Git.remote_add, new_binds = "remote_add_view"},
    },
    ["init"] = {
        { mode = "n", map = "i", action = "<Nop>" },
        { mode = "n", map = "i", callback = M.eval_bind, nested = Git.status, after = M.add_binds },
    },
    ["always"] = {
        { mode = "n", map = "S",     action = "<Nop>"},
        { mode = "n", map = "S",     callback = M.eval_bind, nested = Git.branches, new_binds = "branch_view"},

        { mode = "n", map = "s",     action = "<Nop>" },
        { mode = "n", map = "s",     callback = M.eval_bind, nested = Git.status, new_binds = "defaults" },

        { mode = "n", map = "<C-c>", action = "<Nop>" },
        { mode = "n", map = "<C-c>", callback = M.eval_bind, nested = Git.commit_all, new_binds = "commit_view" },

        { mode = "n", map = "q", action = "<Nop>" },
        { mode = "n", map = "q", callback = M.quit },

        { mode = "n", map = "<Esc>", action = "<Nop>" },
        { mode = "n", map = "<Esc>", callback = M.quit },
    }
}


return M
