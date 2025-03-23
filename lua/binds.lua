local Messages = require("messages")
local Helper = require("utils.init")

local M = {
    current_binds = {},
    always_binds = {}
}

M.status_op = function(callback, args, after, after_args)
    local result
    args = args or {}

    if args.line then
        local file = Helper.get_file_under_cursor()
        result = callback(file)
    elseif args.git_cmd then
        result = callback(args.git_cmd)
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
        for map, mode in pairs(M.current_binds) do
            vim.keymap.del(mode, map, {buffer=M.buf})
        end
        M.current_binds = {}
        vim.api.nvim_clear_autocmds({group = 'BranchAu'})
        for _, map in ipairs(binds) do
            if map.action then
                vim.keymap.set(map.mode, map.map, map.action, {buffer = M.buf})
            else
                vim.keymap.set(map.mode, map.map, function ()
                    local nested = map.nested or nil
                    local args = map.args or nil
                    local after = map.after or nil
                    local after_args = map.after_args or nil
                    local line = map.line or false

                    if nested then
                        map.callback(nested, args, after, after_args, line)
                    end

                end, {buffer = M.buf})
                M.current_binds[map.map] = map.mode
            end
        end
    end
    return M.is_active_repo
end

M.set_always_binds = function ()
    for _, map in ipairs(M.binds.always) do
        if map.action then
            vim.keymap.set(map.mode, map.map, map.action, {buffer = M.buf})
        else
            vim.keymap.set(map.mode, map.map, function ()
                local nested = map.nested or nil
                local args = map.args or nil
                local after = map.after or nil
                local after_args = map.after_args or nil
                local line = map.line or false

                if nested then
                    map.callback(nested, args, after, after_args, line)
                else
                    map.callback()
                end

            end, {buffer = M.buf})
            M.always_binds[map.map] = map.mode
        end
    end
end

M.quit = function ()
    for map, mode in pairs(M.always_binds) do
        vim.keymap.del(mode, map, {buffer=M.buf})
    end
    vim.cmd("quit")
end


return M
