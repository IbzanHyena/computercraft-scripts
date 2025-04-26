if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end
if not os.loadAPI("/apis/sheepfactory") then
    print("Failed to load sheepfactory API")
end

local ModemSide = clientserver.FindModemSide()
rednet.open(ModemSide)
rednet.host(sheepfactory.UpdateProtocol, "controller")
rednet.host(sheepfactory.StartProtocol, "controller")

while true do
    term.clear()
    print("Sheep Factory menu:")
    print("[S]tart")
    print("[U]pdate")

    while true do
        local _, key, _ = os.pullEvent("key")
        if key == keys.s then
            rednet.broadcast(true, sheepfactory.StartProtocol)
            os.run({}, "/sheepfactory/yeendisplay")
            break
        elseif key == keys.u then
            rednet.broadcast(true, sheepfactory.UpdateProtocol)
            sheepfactory.Reinstall("/sheepfactory/controller")
        end
    end
end
