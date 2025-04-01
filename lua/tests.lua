
local function status_note_regex()
    print("STATUS NOTE REGEX TEST:")
    local lines = {
        "  (use git rm --cached <file>... to unstage)",
        "use git rm --cached <file>... to unstage",
        "On branch main"
    }
    local should_be = {
        "",
        "use git rm --cached <file>... to unstage",
        "On branch main"
    }
    for i, line in ipairs(lines)do
        local is = line:gsub(".*%s*%b()$", "")
        assert(is, should_be[i])
        print("\27[32mPassed: \27[0m" .. is)
    end
    print("\n\n")
end


local function file_regex()
    print("FILE REGEX TEST:")
    local lines = {
        "/home/user/documents/file.txt",
        "documents/file.txt",
        "../file.txt",
        "./file.txt",
        "~/documents/file.txt",
        "/home/user/my documents/file.txt",
        "./lua",
        "./",
        "lua/",
        "	lua/",
        "	new file:   lua/git.lua",
        "	new file:   lua/git.lua\n",
        "	modified:   lua/skxxtz-git.lua\n"

    }
    local should_be = {
        "/home/user/documents/file.txt",
        "documents/file.txt",
        "../file.txt",
        "./file.txt",
        "~/documents/file.txt",
        "/home/user/my documents/file.txt",
        "./lua",
        "./",
        "lua/",
        "lua/",
        "lua/git.lua",
        "lua/git.lua",
        "lua/skxxtz-git.lua"
    }
    for i, line in ipairs(lines) do  -- Use ipairs to iterate through the array
        local match = line:match(".-([%w]*[%.%/%~]+[%w%s]*[%w%/%s]*[%.%w%-%_]*)")
        assert(match == should_be[i], "\nNo match for: " .. line)
        print("\27[32mPassed: \27[0m" .. match)
    end
    print("\n\n")
end

local function branch_regex()
    print("BRANCH REGEX TEST:")
    local lines = {
        "  feature/caching",
        "  main",
        "  stable/release-v0.1.2",
        "  stable/release-v0.1.3",
        "  stable/release-v0.1.4",
        "* unstable/release-v0.1.5",
    }
    local should_be = {
        "feature/caching",
        "main",
        "stable/release-v0.1.2",
        "stable/release-v0.1.3",
        "stable/release-v0.1.4",
        "unstable/release-v0.1.5",
    }
    for i, line in ipairs(lines) do
        local _, branch_name = line:match("(%**)%s*(.*)")
        assert(branch_name == should_be[i])

        print("\27[32mPassed: \27[0m" .. branch_name)
    end
    print("\n\n")
end


local function test_advanced_branches()
    print("ADVANCED BRANCH REGEX TEST:")
    local lines = {
        "  feature/caching origin/feature/caching",
        "  main origin/main",
        "  stable/release-v0.1.2 origin/stable/release-v0.1.2",
        "  stable/release-v0.1.3 origin/stable/release-v0.1.3",
        "  stable/release-v0.1.4 origin/stable/release-v0.1.4",
        "* unstable/release-v0.1.5 origin/unstable/release-v0.1.5",
        "* main",
    }
    local should_be = {
        {"", "feature/caching", "origin/feature/caching"},
        {"", "main", "origin/main"},
        {"", "stable/release-v0.1.2", "origin/stable/release-v0.1.2"},
        {"", "stable/release-v0.1.3", "origin/stable/release-v0.1.3"},
        {"", "stable/release-v0.1.4", "origin/stable/release-v0.1.4"},
        {"*", "unstable/release-v0.1.5", "origin/unstable/release-v0.1.5"},
        {"*", "main", ""},
    }
    for i, line in ipairs(lines) do
        local active, name, upstream  = line:match("(%**)%s+(%S+)%s*(%S*)%c?$")
        assert(active == should_be[i][1] and name == should_be[i][2] and upstream == should_be[i][3])
        print("\27[32mPassed: \27[0m" .. name)
    end
    print("\n\n")
end
local function trim()
    print("TRIM TEST")
    local lines = {
        "  feature/caching origin/feature/caching",
        "  main origin/main",
        "  stable/release-v0.1.2 origin/stable/release-v0.1.2",
        "  stable/release-v0.1.3 origin/stable/release-v0.1.3",
        "  stable/release-v0.1.4 origin/stable/release-v0.1.4",
        "* unstable/release-v0.1.5 origin/unstable/release-v0.1.5",
        "* main\n ",
    }
    local should_be = {
        "feature/caching origin/feature/caching",
        "main origin/main",
        "stable/release-v0.1.2 origin/stable/release-v0.1.2",
        "stable/release-v0.1.3 origin/stable/release-v0.1.3",
        "stable/release-v0.1.4 origin/stable/release-v0.1.4",
        "* unstable/release-v0.1.5 origin/unstable/release-v0.1.5",
        "* main",
    }
    for i, line in ipairs(lines) do
        local match  = line:match("^%s*(.-)%s*$")
        assert(match == should_be[i])
        print("\27[32mPassed: \27[0m" .. match)
    end
end
status_note_regex()
file_regex()
branch_regex()
test_advanced_branches()
trim()




