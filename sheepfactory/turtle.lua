if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end

local aspectalyzer = peripheral.wrap("front")

local quota = {terra=10}
local progress = {}

rednet.open("left")
rednet.host("sheepfactory", "turtle")
clientserver.WaitForReceivers("sheepfactory", {"display", "door"})
local displayId = rednet.lookup("sheepfactory", "display")
local doorId = rednet.lookup("sheepfactory", "door")

rednet.send(doorId, false, "sheepfactory")

while true do
    if turtle.suckUp() then
        local count = turtle.getItemCount()
        turtle.drop()
        local aspects = aspectalyzer.getAspectCount()
        for k, v in pairs(aspects) do
            if not progress[k] then
                progress[k] = v
            else
                progress[k] = progress[k] + v * count
            end
        end
        turtle.suck()
        turtle.dropDown()

        local relative = {}
        local finished = true
        for k, v in pairs(quota) do
            relative[k] = math.max(progress[k] / v, 1)
            finished = finished and relative[k] == 1
        end
        rednet.send(displayId, {quota=quota, progress=progress, relative=relative}, "sheepfactory")
        if finished then break end
    else
        sleep(1)
    end
end

rednet.send(doorId, true, "sheepfactory")
