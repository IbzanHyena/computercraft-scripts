if not os.loadAPI("/apis/extraTurtle") then
    print("Failed to load extraTurtle API")
end

local function isWood(data)
    return data ~= nil and string.find(data.name, "log") ~= nil
end

local function isNotWood(data)
    return not isWood(data)
end

local function chopTree()
    turtle.dig()
    extraTurtle.refuelToMin(1)
    extraTurtle.tolerantMove("forward")
    local height = 0
    while true do
        local success, data = turtle.inspectUp()
        if not success or not isWood(data) then
            break
        end

        turtle.digUp()
        extraTurtle.refuelToMin(1, isNotWood)
        extraTurtle.tolerantMove("up")
        height = height + 1
    end

    extraTurtle.refuelToMin(height + 1, isNotWood)
    extraTurtle.tolerantMove("down", height)
    extraTurtle.tolerantMove("back")
end

local function grabSapling()
    while true do
        for i = 1,16 do
            local data = turtle.getItemDetail(i)
            if data ~= nil and string.find(data.name, "sapling") then
                return
            end
        end
        if turtle.suck(1) then return end
        sleep(5)
    end
end

local function returnWood()
    local woodReturned = 0
    for i = 1,16 do
        local data = turtle.getItemDetail(i)
        if isWood(data) then
            turtle.select(i)
            woodReturned = woodReturned + data.count
            turtle.drop()
        end
    end
    return woodReturned
end

local function grabCoal()
    for i = 1,16 do
        local data = turtle.getItemDetail(i)
        if data ~= nil and data.name == "minecraft:coal" then
            turtle.select(i)
            turtle.suck(64 - data.count)
            break
        end
    end
end

local function plantSapling()
    for i = 1,16 do
        local data = turtle.getItemDetail(i)
        if data ~= nil and string.find(data.name, "sapling") then
            turtle.select(i)
            turtle.place()
            return
        end
    end
end

local StartTime = os.clock()
local LastReportTime = StartTime
local ReportInterval = 300
local TreesChopped = 0
local WoodHarvested = 0
while true do
    local now = os.clock()
    if now - LastReportTime >= ReportInterval then
        print("----------")
        print("Now harvested " .. WoodHarvested .. " wood (" .. TreesChopped .. " trees)")
        print("Time taken: " .. now - StartTime .. " s")
        print("Rate: " .. WoodHarvested / StartTime .. " wood/s")
        print("----------")
        LastReportTime = now
    end
    local success, data = turtle.inspect()
    if success and isWood(data) then
        print("Chopping tree")
        chopTree()
        TreesChopped = TreesChopped + 1
        print("Returning wood")
        turtle.turnLeft()
        WoodHarvested = WoodHarvested + returnWood()
        print("Grabbing sapling")
        turtle.turnLeft()
        grabSapling()
        print("Grabbing coal")
        turtle.turnLeft()
        grabCoal()
        print("Planting sapling")
        turtle.turnLeft()
        plantSapling()
    else
        sleep(5)
    end
end
