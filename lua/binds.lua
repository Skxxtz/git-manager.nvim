local Messages = require("messages")
local Helper = require("utils.init")

local M = {}

M.status_op = function(callback, after, after_args, line)
    local result

    if line then
        local file = Helper.get_file_under_cursor()
        result = callback(file)
    else
        result = callback()
    end

    if result then
        print(result)
    end
    if after and not result then
        if after_args then
            after(after_args)
        else
            after()
        end
    else
        Helper.print_to_buffer(result)
    end
end

M.set_binds = function (binds)
    local changed = false
    if binds == M.binds.defaults then
        if M.is_active_repo then
            if M.bindgroup ~= "defaults" then
                M.bindgroup = "defaults"
                changed = true
            end
        else
            if M.bindgroup ~= "init" then
                M.bindgroup = "init"
                binds = M.binds.init
                Helper.print_to_buffer(Messages.is_no_repo)
                changed = true
            end
        end
    elseif binds == M.binds.commit_view then
        if M.bindgroup ~= "commit" then
            M.bindgroup = "commit"
            changed = true
        end

    elseif binds == M.binds.branch_view then
        if  M.bindgroup ~= "branch" then
            M.bindgroup = "branch"
            changed = true
        end
    end

    if changed then
        vim.cmd("mapclear <buffer>")
        vim.api.nvim_clear_autocmds({group = 'BranchAu'})
        for _, map in ipairs(binds) do
            if map.action then
                vim.keymap.set(map.mode, map.map, map.action, {buffer = M.buf})
            else
                vim.keymap.set(map.mode, map.map, function ()
                    local nested = map.nested or nil
                    local after = map.after or nil
                    local after_args = map.after_args or nil
                    local line = map.line or false

                    if nested then
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

    return M.is_active_repo
end


return M
