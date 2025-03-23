local Helper = require("utils.init")

local M = {
    counter = -1,
    last_commit_message = {}
}
M.accept = function ()
    local prompt = M.prompt or "Commit Message:"
    local lines = vim.api.nvim_buf_get_lines(Helper.buf, 0, -1, false)
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

    Helper.execute_shell(cmd)
end
M.next_cached = function ()
    M.counter = M.counter + 1
    local m = M.last_commit_message[#M.last_commit_message - M.counter]
    if m then
        vim.api.nvim_buf_set_lines(Helper.buf, 1, -1, false, vim.fn.split(m, "\n"))
    end
end
M.prev_cached = function ()
    M.counter = M.counter - 1
    local m = M.last_commit_message[#M.last_commit_message - M.counter]
    if m then
        vim.api.nvim_buf_set_lines(Helper.buf, 1, -1, false, vim.fn.split(m, "\n"))
    else
        vim.api.nvim_buf_set_lines(Helper.buf, 1, -1, false, {""})
    end
end


return M
