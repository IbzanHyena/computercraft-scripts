if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end

local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)
local ModemSide = clientserver.FindModemSide()

if ModemSide == nil then
    print("Unable to find modem")
    return
end

rednet.open(ModemSide)
rednet.host("sheepfactory", "sheepdisplay")

while true do
    local _, message, _ = rednet.receive("sheepfactory")
    monitor.clear()
    if message["message"] ~= nil then
        monitor.setCursorPos(1, 1)
        monitor.write(message["message"])
    end
    local y = 0
    for k, v in pairs(message["quota"]) do
        y = y + 1
        monitor.setCursorPos(1, y)
        local displayAspect = (k:gsub("^%l", string.upper))
        local progress = message["progress"][k] or 0
        if progress < v then
            monitor.write(string.format("%s: %d/???", displayAspect, progress))
        else
            monitor.write(string.format("%s: %d/%d", displayAspect, progress, v))
        end
    end
end
