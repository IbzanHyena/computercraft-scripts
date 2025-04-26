print("Sheep Factory: door")

if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end
if not os.loadAPI("/apis/sheepfactory") then
    print("Failed to load sheepfactory API")
end

local ModemSide = clientserver.FindModemSide()

if ModemSide == nil then
    print("Unable to find modem")
    return
end


local function setOutput(b)
    for _, side in pairs(redstone.getSides()) do
        redstone.setOutput(side, b)
    end
end


rednet.open(ModemSide)
rednet.host(sheepfactory.UpdateProtocol, "door")
setOutput(true)

local function main()
    rednet.host(sheepfactory.Protocol, "door")
    while true do
        local _, message, _ = rednet.receive(sheepfactory.Protocol)
        if type(message) == "boolean" then
            setOutput(message)
        end
    end
end


parallel.waitForAny(main, function () sheepfactory.WaitForUpdate("/sheepfactory/door") end)
