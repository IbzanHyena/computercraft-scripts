Protocol = "sheepfactory"
UpdateProtocol = "sheepfactoryupdates"
StartProtocol = "sheepfactorystart"

function Reinstall(startup)
    fs.delete("/apis")
    fs.delete("/sheepfactory")
    os.run({}, "/install")
    fs.delete("/startup")
    fs.copy(startup, "/startup")
    os.reboot()
end


function WaitForUpdate(startup)
    local _, message, _ = rednet.receive(UpdateProtocol)
    if message then Reinstall(startup) end
end
