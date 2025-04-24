if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end

local monitor = peripheral.find("monitor")
local ModemSide = clientserver.FindModemSide()

if ModemSide == nil then
    print("Unable to find modem")
    return
end

rednet.open(ModemSide)
rednet.host("sheepfactory", "display")

while true do
    local _, message, _ = rednet.receive("sheepfactory")
    monitor.clear()
    local y = 0
    for k, v in pairs(message["relative"]) do
        y = y + 1
        monitor.setCursorPos(1, y)
        monitor.write(string.format("%s: %d/%d (%f)", k, message["progress"][k] or 0, message["quota"][k], v or 0))
    end
end
