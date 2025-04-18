function RunReceiver(hostname)
    local ModemSide = nil

    for _, side in pairs(peripheral.getNames()) do
        if peripheral.getType(side) == "modem" then
            ModemSide = side
            break
        end
    end

    if ModemSide == nil then
        print("Unable to find modem")
        return
    end

    rednet.open(ModemSide)
    rednet.host("altarcontrol", hostname)

    while true do
        local _, message = rednet.receive("altarcontrol")
        if message[hostname] ~= nil then
            for _, side in pairs(redstone.getSides()) do
                -- redstone on = ritual disabled
                redstone.setOutput(side, not message[hostname])
            end
        end
    end
end
