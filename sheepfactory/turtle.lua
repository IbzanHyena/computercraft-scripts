if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end

local aspectalyzer = peripheral.wrap("front")

local quota = {terra=10}
local progress = {}

local quotaUpdateFrequency = 30
local quotaUpdateAmount = 5
local quotaUpdateProbability = 0.5

rednet.open("left")
rednet.host("sheepfactory", "turtle")
clientserver.WaitForReceivers("sheepfactory", {"door", "sheepdisplay", "yeendisplay"})
local doorId = rednet.lookup("sheepfactory", "door")
local sheepDisplayId = rednet.lookup("sheepfactory", "sheepdisplay")
local yeenDisplayId = rednet.lookup("sheepfactory", "yeendisplay")

local quotaUpdateTime = os.clock()
local lastProgressTime = os.clock()


local function calculateRelativeProgress()
    local relative = {}
    local finished = true
    for k, v in pairs(quota) do
        relative[k] = math.min((progress[k] or 0) / v, 1)
        finished = finished and relative[k] == 1
    end
    return relative, finished
end


local function updateDisplays()
    local relative, finished = calculateRelativeProgress()
    local data = {quota=quota, progress=progress, relative=relative}
    rednet.send(sheepDisplayId, data, "sheepfactory")
    rednet.send(yeenDisplayId, data, "sheepfactory")
    return finished
end


local function increaseQuota()
    while true do
        if (os.clock() - lastProgressTime) > quotaUpdateFrequency and (os.clock() - quotaUpdateTime) > quotaUpdateFrequency then
            for k, v in pairs(quota) do
                if math.random() < quotaUpdateProbability then
                    quota[k] = v + quotaUpdateAmount
                end
            end
            quotaUpdateTime = os.clock()
            if updateDisplays() then return end
        else
            sleep(1)
        end
    end
end


local function readItems()
    while true do
        if turtle.suckUp() then
            local count = turtle.getItemCount()
            turtle.drop()
            local aspects = aspectalyzer.getAspectCount()
            for k, v in pairs(aspects) do
                progress[k] = math.min((progress[k] or 0) + v * count, quota[k] or math.huge)
            end
            turtle.suck()
            turtle.dropDown()

            lastProgressTime = os.clock()
            if updateDisplays() then return end
        else
            sleep(1)
        end
    end
end

rednet.send(doorId, false, "sheepfactory")
updateDisplays()
parallel.waitForAny(increaseQuota, readItems)
rednet.send(doorId, true, "sheepfactory")
