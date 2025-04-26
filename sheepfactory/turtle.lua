print("Sheep Factory: turtle")

if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end
if not os.loadAPI("/apis/sheepfactory") then
    print("Failed to load sheepfactory API")
end

local quotaAspects = {"corpus", "humanus", "terra", "vinculum"}
local quotaUpdateFrequency = 30
local quotaUpdateAmount = 5
local quotaUpdateProbability = 0.5

local aspectalyzer = peripheral.wrap("front")
rednet.open("left")
rednet.host(sheepfactory.Protocol, "turtle")
rednet.host(sheepfactory.StartProtocol, "turtle")
rednet.host(sheepfactory.UpdateProtocol, "turtle")


local function main()
    clientserver.WaitForReceivers(
        sheepfactory.Protocol,
        {"door", "sheepdisplay", "yeendisplay"}
    )
    local doorId = rednet.lookup(sheepfactory.Protocol, "door")
    local sheepDisplayId = rednet.lookup(sheepfactory.Protocol, "sheepdisplay")
    local yeenDisplayId = rednet.lookup(sheepfactory.Protocol, "yeendisplay")

    local quota = {}

    for _, v in ipairs(quotaAspects) do
        quota[v] = math.random(8, 32)
    end

    local progress = {}
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
        rednet.send(sheepDisplayId, data, sheepfactory.Protocol)
        rednet.send(yeenDisplayId, data, sheepfactory.Protocol)
        return finished
    end


    local function increaseQuota()
        while true do
            if
                (os.clock() - lastProgressTime) > quotaUpdateFrequency
                and (os.clock() - quotaUpdateTime) > quotaUpdateFrequency
            then
                for k, v in pairs(quota) do
                    if
                        (progress[k] or 0) < quota[k]
                        and math.random() < quotaUpdateProbability
                    then
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
            if turtle.suckDown() then
                local count = turtle.getItemCount()
                turtle.drop()
                local aspects = aspectalyzer.getAspectCount()
                for k, v in pairs(aspects) do
                    progress[k] = math.min(
                        (progress[k] or 0) + v * count,
                        quota[k] or math.huge
                    )
                end
                turtle.suck()
                turtle.dropUp()

                lastProgressTime = os.clock()
                if updateDisplays() then return end
            else
                sleep(1)
            end
        end
    end

    rednet.send(doorId, false, sheepfactory.Protocol)
    updateDisplays()
    parallel.waitForAny(increaseQuota, readItems)
    rednet.send(doorId, true, sheepfactory.Protocol)
    rednet.send(yeenDisplayId, true, sheepfactory.Protocol)
end


local function waitForStart()
    while true do
        local _, message, _ = rednet.receive(sheepfactory.StartProtocol)
        if message then main() end
    end
end


parallel.waitForAny(waitForStart, function () sheepfactory.WaitForUpdate("/sheepfactory/turtle") end)
