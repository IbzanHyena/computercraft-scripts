local function reinstall(startup)
    shell.run("/install")
    fs.delete("/startup")
    fs.copy(startup, "/startup")
    os.reboot()
end


local function waitForUpdate(startup)
    local _, message, _ = rednet.receive("sheepfactoryupdates")
    if message then reinstall(startup) end
end
