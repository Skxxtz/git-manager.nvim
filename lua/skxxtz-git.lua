local Messages = require("messages")
local A = {}
local M = {
    last_commit_message = {},
}
local CommitView = {
    counter = -1
}
local BranchView = {}
local Bindings = {}

unpack = unpack or table.unpack



M.show_menu = function (opts)
    opts = opts or {}
    A.win = vim.api.nvim_get_current_win()
    A.buf = vim.api.nvim_win_get_buf(A.win)

    M.binds = M.get_binds()

    local height = opts.height or math.floor(vim.o.lines * 0.2)
    local win_config = {
        split = "below",
        height = height,
        style = "minimal",
        win = A.win,
    }

    M.buf = M.buf or vim.api.nvim_create_buf(false, true)
    M.win = vim.api.nvim_open_win(M.buf, true, win_config)
    vim.api.nvim_buf_set_name(M.buf, "Git")

    vim.api.nvim_create_augroup("BranchAu", {clear = false})

    vim.wo[M.win].foldmethod = "manual"
    if M.set_binds(M.binds.defaults) then
        M.show_status()
    end
end





-- Init
M.init = function ()
    local result = M.execute_shell("git init")
    return result
end

-- Status
M.status = function ()
    M.set_binds(M.binds.defaults)
    local result = M.execute_shell("git status")
    if result and #result > 0 then
        result = result:gsub("%s*%b()", "")
    end
    M.last_cmd = M.status
    return result
end

-- Adding
M.add_file = function (file)
    M.set_binds(M.binds.defaults)
    local result = M.execute_shell("git add " .. file)
    if #result > 0 then
        M.last_cmd = M.add_file
    else
        if M.last_cmd == M.status then
            result = M.last_cmd()
        end
    end
    return result
end
M.add_all = function ()
    M.set_binds(M.binds.defaults)
    local result = M.execute_shell("git add .")
    if #result > 0 then
        M.last_cmd = M.add_all
    else
        if M.last_cmd == M.status then
            result = M.last_cmd()
        end
    end
    return result
end


-- Committing
M.commit_all = function ()
    M.set_binds(M.binds.commit_view)

    CommitView.prompt = "Commit Message:"
    CommitView.prompt = vim.fn.split(CommitView.prompt, "\n")

    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, CommitView.prompt)
    vim.api.nvim_win_set_cursor(M.win, {#CommitView.prompt, 0})
end
CommitView.accept = function ()
    local prompt = CommitView.prompt or "Commit Message:"
    local lines = vim.api.nvim_buf_get_lines(M.buf, 0, -1, false)
    local message = ""
    if #lines >= #prompt + 1 then
        for i, line in ipairs(lines) do
            if i >= #prompt + 1 then
                line = line:gsub('"', "'")
                message = message .. line .. "\n"
            end
        end
    end
    table.insert(M.last_commit_message, message)
    local cmd = string.format('git commit -m "%s"', message)

    M.execute_shell(cmd)
    M.show_status()
end
CommitView.next_cached = function ()
    CommitView.counter = CommitView.counter + 1
    local m = M.last_commit_message[#M.last_commit_message - CommitView.counter]
    if m then
        vim.api.nvim_buf_set_lines(M.buf, 1, -1, false, vim.fn.split(m, "\n"))
    end
end
CommitView.prev_cached = function ()
    CommitView.counter = CommitView.counter - 1
    local m = M.last_commit_message[#M.last_commit_message - CommitView.counter]
    if m then
        vim.api.nvim_buf_set_lines(M.buf, 1, -1, false, vim.fn.split(m, "\n"))
    else
        vim.api.nvim_buf_set_lines(M.buf, 1, -1, false, {""})
    end
end


-- Pushing
M.push = function()
    M.set_binds(M.binds.defaults)
    local result = M.execute_shell("git push", true)
    return result
end

-- Untracking
M.untrack_file = function (file)
    M.set_binds(M.binds.defaults)
    local result = M.execute_shell("git reset " .. file)
    return result
end
M.untrack_all = function ()
    M.set_binds(M.binds.defaults)
    local result = M.execute_shell("git reset")
    if #result > 0 then
        M.last_cmd = M.untrack_all
    else
        if M.last_cmd == M.status then
            result = M.last_cmd()
        end
    end
    return result
end

-- Switch
M.switch =  function ()
    M.set_binds(M.binds.branch_view)
    local branches = M.get_branches()
    M.print_to_buffer(branches)
    vim.keymap.set("n", "<CR>", function ()
        vim.cmd("mapclear <buffer>")
        local line = vim.api.nvim_get_current_line()
        local _, branch_name = line:match("(%**)%s*(.*)")
        M.execute_shell("git switch " .. branch_name)
        M.print_to_buffer(M.switch())
        M.add_normal_binds()
    end, {buffer = M.buf})
end
BranchView.rename = function ()
    vim.api.nvim_clear_autocmds({group = 'BranchAu'})
    local line = vim.api.nvim_get_current_line()
    local _, before = line:match("(%**)%s*(.*)")
    M.rename_tmp = before

    vim.cmd("startinsert")
    vim.cmd("normal! $")
    vim.api.nvim_create_autocmd("InsertLeave", {
        buffer = M.buf,
        group = "BranchAu",
        callback = function ()
            line = vim.api.nvim_get_current_line()
            local _, after = line:match("(%**)%s*(.*)")
            M.execute_shell("git branch -m " .. M.rename_tmp .. " " .. after)
        end
    })
end
BranchView.add = function ()
    vim.api.nvim_clear_autocmds({group = 'BranchAu'})

    local row, col = unpack(vim.api.nvim_win_get_cursor(M.win))

    vim.api.nvim_buf_set_lines(M.buf, row, row, true, {"  "})

    BranchView.cursor_position = {row + 1, 2}
    BranchView.num_lines = vim.api.nvim_buf_line_count(M.buf)

    vim.cmd("startinsert")
    vim.cmd("normal! $")

    -- Insert the line and move cursor to the correct position if needed
    vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI", "WinEnter"}, {
        buffer = M.buf,
        group = "BranchAu",
        callback = function ()
            row, col = unpack(vim.api.nvim_win_get_cursor(M.win))

            local line = vim.api.nvim_get_current_line()

            -- If the line is too short (less than 2 chars), ensure it's indented
            if #line < 2 then
                vim.api.nvim_buf_set_lines(M.buf, BranchView.cursor_position[1]-1, BranchView.cursor_position[1], true, {"  "})
            end

            -- Ensure the cursor stays in the correct position
            if row ~= BranchView.cursor_position[1] or col <= 1 then
                vim.api.nvim_win_set_cursor(M.win, BranchView.cursor_position)
            else
                BranchView.cursor_position[2] = col
            end
        end
    })

    -- When leaving insert mode, handle any line cleanup if needed
    vim.api.nvim_create_autocmd("InsertLeave", {
        buffer = M.buf,
        group = "BranchAu",
        callback = function ()
            vim.api.nvim_clear_autocmds({group = 'BranchAu'})
            local line = vim.api.nvim_get_current_line()

            -- If the new line was empty, delete it
            if #line == 2 then
                vim.api.nvim_buf_set_lines(M.buf, BranchView.cursor_position[1]-1, BranchView.cursor_position[1], false, {})
            else
                print("Line added: " .. line)
            end
        end
    })
end



-- HELPERS
M.show_status = function ()
    local r = M.status()
    M.print_to_buffer(r)
end

M.execute_shell = function (command, show)
    local loc = " 2> /dev/null"
    if show then
        loc = " 2>&1"
    end
    local handle = io.popen(command .. loc)
    if handle then
        local result = handle:read("*a")
        handle:close()
        return result
    end
    return nil
end
M.print_to_buffer = function (string, buffer)
    buffer = buffer or M.buf
    if string then
        if type(string) == "string" then
            string = vim.fn.split(string, "\n")
        end
        vim.api.nvim_buf_set_lines(buffer, 0, -1, true, string)
    end
end

M.is_active_repo = function ()
    local result = M.execute_shell("git rev-parse --is-inside-work-tree")
    if result then
        return result:match("^true") ~= nil
    end
    return false
end
M.get_branches = function ()
    local branches_raw = M.execute_shell("git branch")
    if branches_raw then
        branches_raw = vim.fn.split(branches_raw, "\n")
        return branches_raw
    end
end



Bindings.status_op = function(callback, after, after_args, line)
    local result

    if line then
        local file = M.get_file_under_cursor()
        result = callback(file)
    else
        result = callback()
    end

    if after then
        if after_args then
            after(after_args)
        else
            after()
        end
    else
        M.print_to_buffer(result)  -- Print result if `after` is not provided
    end
end

M.set_binds = function (binds)
    local changed = false
    local is_active_repo = M.is_active_repo()
    if binds == M.binds.defaults then
        if is_active_repo then
            if M.bindgroup ~= "defaults" then
                M.bindgroup = "defaults"
                changed = true
            end
        else
            if M.bindgroup ~= "init" then
                M.bindgroup = "init"
                binds = M.binds.init
                M.print_to_buffer(Messages.is_no_repo)
                changed = true
            end
        end
    elseif binds == M.binds.commit_view then
        if M.bindgroup ~= "commit" then
            M.bindgroup = "commit"
            changed = true
        end
    end

    if changed then
        vim.cmd("mapclear <buffer>")
        for _, map in ipairs(binds) do
            if map.action then
                vim.keymap.set(map.mode, map.map, map.action, {buffer = M.buf})
            else
                vim.keymap.set(map.mode, map.map, function ()
                    local nested = map.nested or nil
                    local after = map.after or nil
                    local after_args = map.after_args or nil
                    local line = map.line or false

                    if M.bindgroup == "init" and after then
                        Bindings.status_op(nested, after, M.binds.defaults, line)
                    elseif nested then
                        map.callback(nested, after, after_args, line)
                    end

                end, {buffer = M.buf})
            end
        end
    end

    vim.keymap.set("n", "q", function ()
        vim.cmd("quit")
    end, {buffer = M.buf })
    vim.keymap.set("n", "<Esc>", function ()
        vim.cmd("quit")
    end, {buffer = M.buf })

    return is_active_repo
end

M.get_file_under_cursor = function ()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(M.win))
    local line = vim.api.nvim_buf_get_lines(M.buf, row-1, row, false)[1]
    local match = line:match(".-([%w]*[%.%/%~]+[%w%s]*[%w%/%s]*[%.%w%-%_]*)")
    return match
end







vim.keymap.set("n", "<leader>ga", function ()
    M.show_menu()
end)

M.get_binds = function ()
    return {
        commit_view = {
            {mode = "n", map = "<C-CR>", callback = Bindings.status_op, nested = CommitView.accept},
            {mode = "n", map = "<UP>", callback = Bindings.status_op, nested = CommitView.next_cached},
            {mode = "n", map = "<DOWN>", callback = Bindings.status_op, nested = CommitView.prev_cached},
        },
        branch_view = {
            {mode = "n", map = "r", action = "<Nop>"},
            {mode = "n", map = "r", callback = Bindings.status_op, nested = BranchView.rename},
            {mode = "n", map = "o", action = "<Nop>"},
            {mode = "n", map = "o", callback = Bindings.status_op, nested = BranchView.add},

        },
        defaults = {
            {mode = "n", map = "u", action = "<Nop>"},
            {mode = "n", map = "u", callback = Bindings.status_op, nested = M.untrack_file, after = M.show_status, line = true},
            {mode = "n", map = "<C-u>", callback = Bindings.status_op, nested = M.untrack_all, after = M.show_status,  line = true},

            {mode = "n", map = "a", action = "<Nop>"},
            {mode = "n", map = "a", callback = Bindings.status_op, nested = M.add_file, after = M.show_status, line = true},
            {mode = "n", map = "<C-a>", callback = Bindings.status_op, nested = M.add_all, after = M.show_status, line = true},

            {mode = "n", map = "<C-c>", action = "<Nop>"},
            {mode = "n", map = "<C-c>", callback = Bindings.status_op, nested = M.commit_all},

            {mode = "n", map = "p", action = "<Nop>"},
            {mode = "n", map = "p", callback = Bindings.status_op, nested = M.push},

            {mode = "n", map = "S", action = "<Nop>"},
            {mode = "n", map = "S", callback = Bindings.status_op, nested = M.switch},

            {mode = "n", map = "s", action = "<Nop>"},
            {mode = "n", map = "s", callback = Bindings.status_op, nested = M.status},
        },
        init = {
            {mode = "n", map = "i", action = "<Nop>"},
            {mode = "n", map = "i", callback = Bindings.status_op, nested = M.status, after = M.add_binds},

        }
    }
end

return M
