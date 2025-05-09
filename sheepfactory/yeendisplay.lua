print("Sheep Factory: yeendisplay")

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
rednet.host(sheepfactory.UpdateProtocol, "yeendisplay")

monitor.setTextColour(colours.white)
monitor.setBackgroundColour(colours.black)
monitor.clear()


local function main()
    rednet.host(sheepfactory.Protocol, "yeendisplay")

    while true do
        local _, message, _ = rednet.receive(sheepfactory.Protocol)
        if type(message) == "boolean" and message then break end
        monitor.setTextColour(colours.white)
        monitor.setBackgroundColour(colours.black)
        monitor.clear()
        local y = 0
        for k, v in pairs(message["quota"]) do
            y = y + 1
            monitor.setCursorPos(1, y)
            local filledW = math.floor((message["relative"][k] or 0) * maxW)
            local text = string.format("%s: %d/%d", (k:gsub("^%l", string.upper)), message["progress"][k] or 0, v)
            local filledSubstring = string.sub(text, 1, filledW)
            monitor.setTextColour(colours.black)
            monitor.setBackgroundColour(colours.white)
            monitor.write(filledSubstring)
            if filledW > #filledSubstring then
                monitor.write(string.rep(" ", filledW - #filledSubstring))
            end
            monitor.setTextColour(colours.white)
            monitor.setBackgroundColour(colours.black)
            if #filledSubstring < #text then
                monitor.write(string.sub(text, #filledSubstring + 1))
            end
        end
    end

    rednet.unhost(sheepfactory.Protocol, "yeendisplay")
end


parallel.waitForAny(main, function () sheepfactory.WaitForUpdate("/sheepfactory/yeendisplay") end)
