
local function status_note_regex()
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
        print("Passed: " .. is)
    end
end


local function file_regex()
    print("FILE REGEX TEST:\n")
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
        print("Passed: " .. match)
    end
    print("\n\n\n")
end

function branch_regex()
    lines = {
        "  feature/caching",
        "  main",
        "  stable/release-v0.1.2",
        "  stable/release-v0.1.3",
        "  stable/release-v0.1.4",
        "* unstable/release-v0.1.5",
    }
    for i, line in ipairs(lines) do
        local star, branch_name = line:match("(%**)%s*(.*)")
        print(star, branch_name)
    end
    
end

branch_regex()
