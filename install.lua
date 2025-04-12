local argv = { ... }

local urlRoot = "https://raw.githubusercontent.com/IbzanHyena/computercraft-scripts/refs/heads/main/"
local installRoot = argv[1] or "/"

if installRoot:sub(-1) ~= "/" then
    installRoot = installRoot .. "/"
end

local installTargets = {
    "apis/extraTurtle",
    "farm",
    "lwdexcavate",
    "mine",
    "wget",
}

local function install(target)
    local targetPath = installRoot .. target

    -- make parent if necessary
    local parent = fs.getDir(targetPath)
    if not fs.exists(parent) then
        fs.makeDir(parent)
    end

    -- now test for existence of the current file and replace if needed
    if fs.exists(targetPath) then
        fs.delete(targetPath)
    end

    -- finally, acquire the file
    local response = http.get(urlRoot .. target .. ".lua")
    if not response then return end
    local file = fs.open(targetPath, "w")
    file.write(response.readAll())
    file.close()
end

for _, t in ipairs(installTargets) do
    install(t)
end
