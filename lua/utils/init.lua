local M = {
    win = nil,
    buf = nil
}

M.get_file_under_cursor = function ()
    local line = vim.api.nvim_get_current_line()
    local match = line:match(".-([%w]*[%.%/%~]+[%w%s]*[%w%/%s]*[%.%w%-%_]*)")
    return match
end
M.get_branch_under_cursor = function ()
    local line = vim.api.nvim_get_current_line()
    local active, branch = line:match("%s*(%**)%s*(.*)")
    if active then
        active = true
    end
    return {name = branch, active = active or false, raw_line = line}
end

M.lock_line = function (row_bound, col_bound, fixed_lines)
    local row, col = unpack(vim.api.nvim_win_get_cursor(M.win))
    M.cursor_position = {row, col}
    vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI", "WinEnter", "TextChangedI"}, {
        buffer = M.buf,
        group = "BranchAu",
        callback = function ()
            row, col = unpack(vim.api.nvim_win_get_cursor(M.win))
            if  (row_bound.lower and row <= row_bound.lower) or
                (row_bound.upper and row >= row_bound.upper) or
                (col_bound.lower and col <= col_bound.lower) or
                (col_bound.upper and col >= col_bound.upper) then

                local num_lines = vim.api.nvim_buf_line_count(M.buf)
                local num_cols = #vim.api.nvim_get_current_line()
                if  (row_bound.lower and (num_lines <= row_bound.lower)) or
                    (fixed_lines and num_lines <= fixed_lines) then
                    vim.api.nvim_buf_set_lines(M.buf, M.cursor_position[1]-1, M.cursor_position[1]-1, false, {string.rep(" ", col_bound.lower or 0)})
                end
                if  (col_bound.lower and (num_cols <= col_bound.lower)) then
                    vim.api.nvim_buf_set_lines(M.buf, M.cursor_position[1]-1, M.cursor_position[1], false, {string.rep(" ", col_bound.lower or 0)})
                    M.cursor_position[2] = col_bound.lower + 1
                end

                vim.api.nvim_win_set_cursor(M.win, M.cursor_position)
            else
                M.cursor_position[1] = row
                M.cursor_position[2] = col
            end
        end
    })
end

M.print_to_buffer = function (line, buffer, highlights)
    buffer = buffer or M.buf
    highlights = highlights or {
        ["error:"] = "ErrorMsg",
        ["fatal:"] = "ErrorMsg",
    }
    if line then
        if type(line) == "string" then
            line = vim.fn.split(line, "\n")
        end
        vim.api.nvim_buf_set_lines(buffer, 0, -1, true, line)
        for sub, hl_group in pairs(highlights)do
            for i, l in ipairs(line) do
                local x1, x2 = string.find(l, sub, 1, true)
                if x1 and x2 then
                    vim.api.nvim_buf_add_highlight(buffer, M.ns_id, hl_group, i - 1, x1 - 1, x2  )
                end
            end
        end
    end
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

M.trim = function (string)
    if string then
        return string:match("^%s*(.-)%s*$")
    end
    return ""
end



return M
