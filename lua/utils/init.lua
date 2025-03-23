local M = {}

M.get_file_under_cursor = function ()
    local row, _ = unpack(vim.api.nvim_win_get_cursor(M.win))
    local line = vim.api.nvim_buf_get_lines(M.buf, row-1, row, false)[1]
    local match = line:match(".-([%w]*[%.%/%~]+[%w%s]*[%w%/%s]*[%.%w%-%_]*)")
    return match
end

M.print_to_buffer = function (line, buffer, highlights)
    buffer = buffer or M.buf
    highlights = highlights or {
        ["error:"] = "ErrorMsg",
        ["fatal"] = "ErrorMsg",
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
        return string:match("%s*(.*)%s*")
    end
    return ""
end




return M
