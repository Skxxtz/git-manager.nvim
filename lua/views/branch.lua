local Helper = require("utils.init")
local M = {}

M.rename = function ()
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
M.add = function ()
    vim.api.nvim_clear_autocmds({group = 'BranchAu'})

    local row, col = unpack(vim.api.nvim_win_get_cursor(Helper.win))

    vim.api.nvim_buf_set_lines(Helper.buf, row, row, true, {"  "})

    M.cursor_position = {row + 1, 2}
    M.num_lines = vim.api.nvim_buf_line_count(Helper.buf)
    print(vim.inspect(M.cursor_position))

    vim.cmd("startinsert")
    vim.cmd("normal! $")

    -- Insert the line and move cursor to the correct position if needed
    vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI", "WinEnter"}, {
        buffer = Helper.buf,
        group = "BranchAu",
        callback = function ()
            row, col = unpack(vim.api.nvim_win_get_cursor(Helper.win))

            local line = vim.api.nvim_get_current_line()

            -- If the line is too short (less than 2 chars), ensure it's indented
            if #line < 2 then
                vim.api.nvim_buf_set_lines(Helper.buf, M.cursor_position[1]-1, M.cursor_position[1], true, {"  "})
            end

            -- Ensure the cursor stays in the correct position
            if row ~= M.cursor_position[1] or col <= 1 then
                vim.api.nvim_win_set_cursor(Helper.win, M.cursor_position)
            else
                M.cursor_position[2] = col
            end
        end
    })

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
