function Reinstall(startup)
    os.run({}, "/install")
    fs.delete("/startup")
    fs.copy(startup, "/startup")
    os.reboot()
end


function WaitForUpdate(startup)
    local _, message, _ = rednet.receive("sheepfactoryupdates")
    if message then Reinstall(startup) end
end
