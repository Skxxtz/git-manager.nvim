local Helper = require("utils.init")

local M = {
    counter = -1,
    last_message = {}
}
M.show = function (opts)
    opts = opts or {}
    local tmp = opts.prompt or ""
    local line_start = opts.content or ""
    M.prompt = vim.fn.split(tmp, "\n")
    M.cmd = opts.git_cmd or 'git commit -m "%s"'

    vim.api.nvim_buf_set_lines(Helper.buf, 0, -1, false, M.prompt)
    vim.api.nvim_buf_set_lines(Helper.buf, #M.prompt, #M.prompt, false, {line_start})
    vim.api.nvim_win_set_cursor(Helper.win, { #M.prompt + 1, #line_start })

    Helper.lock_line({lower = #M.prompt, upper = nil}, {lower = nil, upper = nil})
end

M.accept = function (_)
    local prompt = M.prompt or "Commit Message:"
    local lines = vim.api.nvim_buf_get_lines(Helper.buf, 0, -1, false)
    local message_lines = {}
    if #lines >= #prompt + 1 then
        for i, line in ipairs(lines) do
            if i >= #prompt + 1 then
                line = Helper.trim(line:gsub('"', "'"))
                table.insert(message_lines, line)
            end
        end
    end
    local message = table.concat(message_lines, "\n")
    table.insert(M.last_message, message)
    local cmd = string.format(M.cmd, message)
    local result, exit_code = Helper.execute_shell(cmd)
    if exit_code ~= 0 then
        return result
    end
end
M.next_cached = function (_)
    M.counter = M.counter + 1
    local m = M.last_message[#M.last_message - M.counter]
    if m then
        vim.api.nvim_buf_set_lines(Helper.buf, 1, -1, false, vim.fn.split(m, "\n"))
    end
end
M.prev_cached = function (_)
    M.counter = M.counter - 1
    local m = M.last_message[#M.last_message - M.counter]
    if m then
        vim.api.nvim_buf_set_lines(Helper.buf, 1, -1, false, vim.fn.split(m, "\n"))
    else
        vim.api.nvim_buf_set_lines(Helper.buf, 1, -1, false, {""})
    end
end


return M
