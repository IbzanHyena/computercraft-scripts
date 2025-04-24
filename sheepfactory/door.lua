if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end

local ModemSide = clientserver.FindModemSide()

if ModemSide == nil then
    print("Unable to find modem")
    return
end

rednet.open(ModemSide)
rednet.host("sheepfactory", "door")

while true do
    local _, message, _ = rednet.receive("sheepfactory")
    if type(message) == "boolean" then
        for _, side in pairs(redstone.getSides()) do
            redstone.setOutput(side, message)
        end
    end
end
