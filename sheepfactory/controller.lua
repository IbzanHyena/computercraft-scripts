if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end

local ModemSide = clientserver.FindModemSide()
rednet.open(ModemSide)
rednet.host("sheepfactoryupdates", "controller")
rednet.host("sheepfactorystart", "controller")

while true do
    term.clear()
    print("Sheep Factory menu:")
    print("[S]tart")
    print("[U]pdate")

    while true do
        local _, key, _ = os.pullEvent("key")
        if key == keys.s then
            rednet.broadcast("sheepfactorystart", true)
            shell.run("/sheepfactory/yeendisplay")
        elseif key == keys.u then
            rednet.broadcast("sheepfactoryupdates", true)
        end
    end
end
