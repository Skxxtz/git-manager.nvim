local Helper = require("utils.init")
local M = {}

M.switch = function (_)
    local line = vim.api.nvim_get_current_line()
    local _, branch_name = line:match("(%**)%s*(.*)")
    local r = Helper.execute_shell("git switch " .. branch_name, true)
    if r then
        if string.find(r, "Switched") then
            return false
        elseif string.find(r, "error:") then
            return r
        end
    end
end
M.delete = function (_)
    local line = vim.api.nvim_get_current_line()
    local _, branch_name = line:match("(%**)%s*(.*)")
    local r;
    if branch_name ~= "main" and branch_name ~= "master" then
        r = Helper.execute_shell("git branch --delete " .. branch_name)
        return false
    else
        r = "error: you should not remove your main/master branch!"
        return r
    end
end
M.rename = function (_)
    vim.api.nvim_clear_autocmds({group = 'BranchAu'})
    local line = vim.api.nvim_get_current_line()
    local _, before = line:match("(%**)%s*(.*)")
    M.rename_tmp = before

    vim.cmd("startinsert")
    vim.cmd("normal! $")
    vim.api.nvim_create_autocmd("InsertLeave", {
        buffer = Helper.buf,
        group = "BranchAu",
        callback = function ()
            line = vim.api.nvim_get_current_line()
            local _, after = line:match("(%**)%s*(.*)")
            Helper.execute_shell("git branch -m " .. M.rename_tmp .. " " .. after)
        end
    })
end
M.add = function (args)
    args = args or {}
    vim.api.nvim_clear_autocmds({group = 'BranchAu'})

    local row, _ = unpack(vim.api.nvim_win_get_cursor(Helper.win))
    local row_start = args.content or "  "
    vim.api.nvim_buf_set_lines(Helper.buf, row, row, true, {row_start})

    M.cursor_position = {row + 1, 2}
    M.num_lines = vim.api.nvim_buf_line_count(Helper.buf)
    vim.api.nvim_win_set_cursor(Helper.win, M.cursor_position)
    Helper.lock_line({lower = row, uppper = row+2},{lower = 2, upper = nil}, M.num_lines - 1)

    vim.cmd("startinsert")
    vim.cmd("normal! $")

    -- When leaving insert mode, handle any line cleanup if needed
    vim.api.nvim_create_autocmd("InsertLeave", {
        buffer = Helper.buf,
        group = "BranchAu",
        callback = function ()
            vim.api.nvim_clear_autocmds({group = 'BranchAu'})
            local line = vim.api.nvim_get_current_line()

            -- If the new line was empty, delete it
            if #line == 2 then
                vim.api.nvim_buf_set_lines(Helper.buf, M.cursor_position[1]-1, M.cursor_position[1], false, {})
            else
                line = Helper.trim(line)
                Helper.execute_shell("git branch " .. line)
            end
        end
    })
end


return M
