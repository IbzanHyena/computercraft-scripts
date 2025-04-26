print("Sheep Factory: sheepdisplay")

if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end
if not os.loadAPI("/apis/sheepfactory") then
    print("Failed to load sheepfactory API")
end

local monitor = peripheral.find("monitor")
local maxW, _ = monitor.getSize()
local ModemSide = clientserver.FindModemSide()

if ModemSide == nil then
    print("Unable to find modem")
    return
end

rednet.open(ModemSide)
rednet.host("sheepfactory", "sheepdisplay")
rednet.host("sheepfactoryupdates", "sheepdisplay")

local function main()
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
                monitor.setTextColour(colours.white)
                monitor.setBackgroundColour(colours.black)
                monitor.write(string.format("%s: %d/???", displayAspect, progress))
                monitor.setTextColour(colours.black)
                monitor.setBackgroundColour(colours.white)
            else
                local text = string.format("%s: %d/%d", displayAspect, progress, v)
                monitor.write(text)
                monitor.write(string.rep(" ", maxW - #text))
            end
        end
    end
end


parallel.waitForAny(main, function() sheepfactory.waitForUpdate("sheepdisplay") end)
