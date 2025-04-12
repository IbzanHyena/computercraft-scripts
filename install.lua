local argv = { ... }

local urlRoot = "https://raw.githubusercontent.com/IbzanHyena/computercraft-scripts/refs/heads/main/"
local installRoot = argv[1] or "/"

if installRoot:sub(-1) ~= "/" then
    installRoot = installRoot .. "/"
end

local response = http.get(urlRoot .. "installTargets.txt")
if not response then
    print("unable to retrieve install targets")
    return
end

local installTargets = {}
string.gsub(
    response.readAll(),
    "(%a+)",
    function(w) table.insert(installTargets, w) end
)
print("Installing " .. #installTargets .. " files")

local function install(target)
    io.write("Installing " .. target .. "...")
    io.flush()
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
    if not response then
        print(" no response")
        return
    end
    local file = fs.open(targetPath, "w")
    file.write(response.readAll())
    file.close()
    print(" success")
end

for _, t in ipairs(installTargets) do
    install(t)
end
