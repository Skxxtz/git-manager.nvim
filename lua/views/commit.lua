local Helper = require("utils.init")

local M = {
    counter = -1,
    last_commit_message = {}
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
                line = line:gsub('"', "'")
                table.insert(message_lines, line)
            end
        end
    end
    local message = table.concat(message_lines, "\n")
    table.insert(M.last_commit_message, message)
    local cmd = string.format(M.cmd, message)
    print(vim.inspect(cmd))
    Helper.execute_shell(cmd)
end
M.next_cached = function (_)
    M.counter = M.counter + 1
    local m = M.last_commit_message[#M.last_commit_message - M.counter]
    if m then
        vim.api.nvim_buf_set_lines(Helper.buf, 1, -1, false, vim.fn.split(m, "\n"))
    end
end
M.prev_cached = function (_)
    M.counter = M.counter - 1
    local m = M.last_commit_message[#M.last_commit_message - M.counter]
    if m then
        vim.api.nvim_buf_set_lines(Helper.buf, 1, -1, false, vim.fn.split(m, "\n"))
    else
        vim.api.nvim_buf_set_lines(Helper.buf, 1, -1, false, {""})
    end
end


return M
