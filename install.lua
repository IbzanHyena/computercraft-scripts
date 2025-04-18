local argv = { ... }

local identityFile = "/identity"
local urlRoot = "https://raw.githubusercontent.com/IbzanHyena/computercraft-scripts/refs/heads/main/"
local targetGroup = argv[1]
local installRoot = argv[2] or "/"

if targetGroup == nil and fs.exists(identityFile) then
    local file = fs.open(identityFile, "r")
    targetGroup = file.readAll()
    file.close()
elseif targetGroup == nil then
    targetGroup = "*"
elseif targetGroup ~= nil then
    local file = fs.open(identityFile, "w")
    file.write(targetGroup)
    file.flush()
    file.close()
end

if installRoot:sub(-1) ~= "/" then
    installRoot = installRoot .. "/"
end

local response = http.get(urlRoot .. "installTargets")
if not response then
    print("unable to retrieve install targets")
    return
end

local installTargets = textutils.unserialise(response.readAll())
response.close()

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
    response.close()
    file.close()
    print(" success")
end

local function installGroup(k, tg)
    if targetGroup == "*" or k == "*" or string.find(targetGroup, k) then
        print("Installing target group " .. k)
        for _, target in pairs(tg) do
            install(target)
        end
    end
end

for k, tg in pairs(installTargets) do
    installGroup(k, tg)
end
