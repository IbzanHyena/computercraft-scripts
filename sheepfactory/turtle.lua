if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end

local aspectalyzer = peripheral.wrap("front")

local quota = {terra=10}
local progress = {}

rednet.open("left")
rednet.host("sheepfactory", "turtle")
clientserver.WaitForReceivers("sheepfactory", {"door", "sheepdisplay", "yeendisplay"})
local doorId = rednet.lookup("sheepfactory", "door")
local sheepDisplayId = rednet.lookup("sheepfactory", "sheepdisplay")
local yeenDisplayId = rednet.lookup("sheepfactory", "yeendisplay")

rednet.send(doorId, false, "sheepfactory")
rednet.send(sheepDisplayId, {quota=quota, progress=progress, relative={}}, "sheepfactory")
rednet.send(yeenDisplayId, {quota=quota, progress=progress, relative={}}, "sheepfactory")

while true do
    if turtle.suckUp() then
        local count = turtle.getItemCount()
        turtle.drop()
        local aspects = aspectalyzer.getAspectCount()
        for k, v in pairs(aspects) do
            progress[k] = (progress[k] or 0) + v * count
        end
        turtle.suck()
        turtle.dropDown()

        local relative = {}
        local finished = true
        for k, v in pairs(quota) do
            relative[k] = math.min((progress[k] or 0) / v, 1)
            finished = finished and relative[k] == 1
        end
        local data = {quota=quota, progress=progress, relative=relative}
        rednet.send(sheepDisplayId, data, "sheepfactory")
        rednet.send(yeenDisplayId, data, "sheepfactory")
        if finished then break end
    else
        sleep(1)
    end
end

rednet.send(doorId, true, "sheepfactory")
