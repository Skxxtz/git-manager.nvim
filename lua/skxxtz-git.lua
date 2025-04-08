local Helper = require("utils.init")

local Git = require("git")
Git.setup()
local Binds = require("binds")

local A = {}
local M = {
}

unpack = unpack or table.unpack



M.show_menu = function (opts)
    opts = opts or {}
    A.win = vim.api.nvim_get_current_win()
    A.buf = vim.api.nvim_win_get_buf(A.win)

    local height = opts.height or 10
    local win_config = {
        split = "below",
        height = height,
        style = "minimal",
        win = A.win,
    }

    M.buf = Helper.buf or vim.api.nvim_create_buf(false, true)
    M.win = vim.api.nvim_open_win(M.buf, true, win_config)

    vim.api.nvim_create_augroup("BranchAu", {clear = false})

    Helper.ns_id = vim.api.nvim_create_namespace("skxxtz-git")
    vim.api.nvim_win_set_hl_ns(M.win, Helper.ns_id)  -- activate the ns group

    vim.api.nvim_set_hl(Helper.ns_id, "Warning", { fg = "#D5C67A" })
    vim.api.nvim_set_hl(Helper.ns_id, "Error", { fg = "#A35655" })
    vim.api.nvim_set_hl(Helper.ns_id, "Accent", { fg = "#3E4C5E" })

    vim.wo[M.win].foldmethod = "manual"

    vim.api.nvim_buf_set_name(M.buf, "Git")

    Helper.win = M.win
    Helper.buf = M.buf

    Binds.set_always_binds()

    if Binds.set_binds("defaults") then
        Git.show_status()
    end

end

vim.keymap.set("n", "<leader>ga", function ()
    if not M.buf or not vim.api.nvim_buf_is_loaded(M.buf) then
        M.show_menu()
        Helper.active = true
    end
end)


return M
