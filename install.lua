local argv = { ... }

local installRoot = argv[1] or "/"

if installRoot[installRoot:len()] ~= "/" then
    installRoot = installRoot .. "/"
end

local installTargets = {}
installTargets["apis/extraTurtle"] = "0Tg4reBi"
installTargets["farm"] = "YF70yHCV"
installTargets["lwdexcavate"] = "5tUKnEbA"
installTargets["mine"] = "rtq1TzEj"

local function install(target, slug)
    -- make parent if necessary
    local parent = fs.getDir(target)
    if not fs.exists(parent) then
        fs.makeDir(parent)
    end

    -- now test for existence of the current file and replace if needed
    if fs.exists(target) then
        fs.delete(target)
    end

    -- finally, acquire the file
    shell.run("/pastebin", "get", slug, target)
end

for target, slug in pairs(installTargets) do
    install(installRoot .. target, slug)
end
