local Messages = require("messages")
local A = {}
local M = {
    last_commit_message = {}
}
-- Init
M.init = function ()
    local result = M.execute_shell("git init")
    return result
end

-- Status
M.status = function ()
    local result = M.execute_shell("git status")
    if result and #result > 0 then
        result = result:gsub("%s*%b()", "")
    end
    M.last_cmd = M.status
    return result
end

-- Adding
M.add_file = function (file)
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
    local prompt = "Commit Message:"
    prompt = vim.fn.split(prompt, "\n")

    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, prompt)
    vim.api.nvim_win_set_cursor(M.win, {#prompt, 0})

    vim.keymap.set("n", "<C-CR>", function ()
        vim.keymap.del("n", "<C-CR>", {buffer=M.buf})
        vim.keymap.del("n", "<UP>", {buffer=M.buf})
        vim.keymap.del("n", "<C-BS>", {buffer=M.buf})
        vim.keymap.del("n", "<DOWN>", {buffer=M.buf})
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
    end, {buffer=M.buf})

    vim.keymap.set("n", "<C-BS>", function ()
        vim.keymap.del("n", "<C-BS>", {buffer=M.buf})
        vim.keymap.del("n", "<C-CR>", {buffer=M.buf})
        vim.keymap.del("n", "<UP>", {buffer=M.buf})
        vim.keymap.del("n", "<DOWN>", {buffer=M.buf})
        if M.last_cmd == M.status() then
            M.show_status()
        end
    end, {buffer=M.buf})

    local counter = -1
    vim.keymap.set("n", "<UP>", function ()
        counter = counter + 1
        local m = M.last_commit_message[#M.last_commit_message - counter]
        if m then
            vim.api.nvim_buf_set_lines(M.buf, 1, -1, false, vim.fn.split(m, "\n"))
        end

    end, {buffer=M.buf})
    vim.keymap.set("n", "<DOWN>", function ()
        counter = counter - 1
        local m = M.last_commit_message[#M.last_commit_message - counter]
        if m then
            vim.api.nvim_buf_set_lines(M.buf, 1, -1, false, vim.fn.split(m, "\n"))
        else
            vim.api.nvim_buf_set_lines(M.buf, 1, -1, false, {""})
        end

    end, {buffer=M.buf})

end


-- Untracking
M.untrack_file = function (file)
    local result = M.execute_shell("git reset " .. file)
    if #result > 0 then
        M.last_cmd = M.untrack_file
    else
        if M.last_cmd == M.status then
            result = M.last_cmd()
        end
    end
    return result
end
M.untrack_all = function ()
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

    vim.keymap.set("n", "r", function ()
        local line = vim.api.nvim_get_current_line()
        local _, before = line:match("(%**)%s*(.*)")
        M.rename_tmp = before

        vim.cmd("startinsert")
        vim.cmd("normal! $")
        vim.api.nvim_create_autocmd("InsertLeave", {
            buffer = M.buf,
            callback = function ()
                line = vim.api.nvim_get_current_line()
                local _, after = line:match("(%**)%s*(.*)")
                M.execute_shell("git branch -m " .. M.rename_tmp .. " " .. after)
            end
        })
    end, {buffer = M.buf})
end

-- Branching

-- HELPERS
M.show_status = function ()
    local r = M.status()
    M.print_to_buffer(r)
end

M.execute_shell = function (command)
    local handle = io.popen(command .. " 2> /dev/null")
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

M.add_normal_binds = function ()
    local is_repo = false
    if M.is_active_repo() then
        is_repo = true
        -- Unset keymaps
        vim.keymap.set('n', 'i', '<Nop>', { noremap = true, silent = true, buffer = M.buf})
        vim.keymap.set('n', 'a', '<Nop>', { noremap = true, silent = true, buffer = M.buf})
        vim.keymap.set('n', 's', '<Nop>', { noremap = true, silent = true, buffer = M.buf})
        vim.keymap.set('n', 'S', '<Nop>', { noremap = true, silent = true, buffer = M.buf})
        vim.keymap.set('n', 'c', '<Nop>', { noremap = true, silent = true, buffer = M.buf})
        vim.keymap.set('n', 'p', '<Nop>', { noremap = true, silent = true, buffer = M.buf})
        vim.keymap.set('n', 'r', '<Nop>', { noremap = true, silent = true, buffer = M.buf})
        vim.keymap.set('n', 'u', '<Nop>', { noremap = true, silent = true, buffer = M.buf})
        vim.keymap.set('n', '<C-c>', '<Nop>', { noremap = true, silent = true, buffer = M.buf})


        -- Untracking 'git reset'
        vim.keymap.set("n", "u", function ()
            local file = M.get_file_under_cursor()
            local result = M.untrack_file(file)
            M.print_to_buffer(result)
        end, { buffer = M.buf })
        vim.keymap.set("n", "<C-u>", function ()
            local r = M.untrack_all()
            M.print_to_buffer(r)
        end, { buffer = M.buf })


        -- Adding 'git add'
        vim.keymap.set("n", "a", function ()
            local file = M.get_file_under_cursor()
            print(file)
            local r = M.add_file(file)
            M.print_to_buffer(r)
        end, { buffer = M.buf })
        vim.keymap.set("n", "<C-a>", function ()
            local r = M.add_all()
            M.print_to_buffer(r)
        end, { buffer = M.buf })


        -- Committing 'git commit -m'
        vim.keymap.set("n", "<C-c>", function ()
            local r = M.commit_all()
            M.print_to_buffer(r)
        end, { buffer = M.buf })
        vim.keymap.set("n", "c", function ()
            local r = M.commit_file()
            M.print_to_buffer(r)
        end, { buffer = M.buf })

        -- Switch
        vim.keymap.set("n", "S", function ()
            local r = M.switch()
            M.print_to_buffer(r)
        end, { buffer = M.buf })

        -- Status
        vim.keymap.set("n", "s", function ()
            local r = M.status()
            M.print_to_buffer(r)
        end, { buffer = M.buf })
    else
        -- Initialization 'git init'
        vim.keymap.set("n", "i", function ()
            local r = M.init()
            M.print_to_buffer(r)
            if #r > 0 then
                M.add_normal_binds()
            end
        end, { buffer = M.buf })
        M.print_to_buffer(Messages.is_no_repo)
    end

    vim.keymap.set("n", "q", function ()
        vim.cmd("quit")
    end, {buffer = M.buf })
    vim.keymap.set("n", "<Esc>", function ()
        vim.cmd("quit")
    end, {buffer = M.buf })

    return is_repo
end

M.get_file_under_cursor = function ()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(M.win))
    local line = vim.api.nvim_buf_get_lines(M.buf, row-1, row, false)[1]
    local match = line:match(".-([%w]*[%.%/%~]+[%w%s]*[%w%/%s]*[%.%w%-%_]*)")
    return match
end


M.show_menu = function (opts)
    opts = opts or {}
    A.win = vim.api.nvim_get_current_win()
    A.buf = vim.api.nvim_win_get_buf(A.win)

    local height = opts.height or math.floor(vim.o.lines * 0.2)
    local win_config = {
        split = "below",
        height = height,
        style = "minimal",
        win = A.win,
    }

    M.buf = vim.api.nvim_create_buf(false, true)
    M.win = vim.api.nvim_open_win(M.buf, true, win_config)

    vim.wo[M.win].foldmethod = "manual"
    if M.add_normal_binds() then
        M.show_status()
    end
end





vim.keymap.set("n", "<leader>ga", function ()
    M.show_menu()
end)



return M
