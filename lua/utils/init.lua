local M = {}

M.get_file_under_cursor = function ()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(M.win))
    local line = vim.api.nvim_buf_get_lines(M.buf, row-1, row, false)[1]
    local match = line:match(".-([%w]*[%.%/%~]+[%w%s]*[%w%/%s]*[%.%w%-%_]*)")
    return match
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



return M
