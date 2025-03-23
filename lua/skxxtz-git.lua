local Helpers = require("utils.init")

local Git = require("git")
Git.setup()
local Binds = require("binds")

local A = {}
local M = {}

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

    M.buf = Helpers.buf or vim.api.nvim_create_buf(false, true)
    M.win = vim.api.nvim_open_win(M.buf, true, win_config)

    vim.api.nvim_create_augroup("BranchAu", {clear = false})

    Helpers.ns_id = vim.api.nvim_create_namespace("skxxtz-git")
    vim.api.nvim_set_hl(Helpers.ns_id, "YellowBg", { bg = "Yellow", fg = "Black" })

    vim.wo[M.win].foldmethod = "manual"

    vim.api.nvim_buf_set_name(M.buf, "Git")

    Helpers.win = M.win
    Helpers.buf = M.buf

    Binds.set_always_binds()

    if Binds.set_binds("defaults") then
        Git.show_status()
    end
end

vim.keymap.set("n", "<leader>ga", function ()
    M.show_menu()
end)


return M
