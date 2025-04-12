local argv = { ... }

if not os.loadAPI("/apis/extraTurtle") then
    print("Failed to load extraTurtle API")
end

if #argv > 1 then
    print("Usage: lumberjack [length]")
    return
end

local Length = tonumber(argv[1])

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

local function grabSaplings()
    for i = 1,16 do
        local data = turtle.getItemDetail(i)
        if data ~= nil and string.find(data.name, "sapling") then
            turtle.select(i)
            turtle.suck(64 - data.count)
            return
        end
    end
    -- we found no saplings, so just grab into this slot
    turtle.suck()
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

local function service()
    turtle.turnLeft()
    local wh = returnWood()
    turtle.turnLeft()
    grabSaplings()
    turtle.turnLeft()
    grabCoal()
    turtle.turnLeft()
    return wh
end

local function printReport(now)
    if now == nil then now = os.clock() end
    print("Now harvested " .. WoodHarvested .. " wood (" .. TreesChopped .. " trees)")
    print("Time taken: " .. now - StartTime .. " s")
    print("Rate: " .. WoodHarvested / (now - StartTime) .. " wood/s")
    print("----------")
end

local function tryChopTree()
    local success, data = turtle.inspect()
    if not success or isNotWood(data) then
        return false
    end
    chopTree()
    return true
end

local function harvestOne()
    while true do
        local now = os.clock()
        if now - LastReportTime >= ReportInterval then
            printReport(now)
            LastReportTime = now
        end
        if tryChopTree() then
            TreesChopped = TreesChopped + 1
            local wh = service()
            WoodHarvested = WoodHarvested + wh
            plantSapling()
        else
            sleep(5)
        end
    end
end

local function harvestRow()
    while true do
        extraTurtle.refuelToMin(Length, isNotWood)
        for _ = 1,Length do
            -- necessary in case we chopped down a tree last iteration
            extraTurtle.refuelToMin(1, isNotWood)
            extraTurtle.tolerantMove("forward")
            turtle.turnRight()
            if tryChopTree() then
                plantSapling()
                TreesChopped = TreesChopped + 1
            end
            turtle.turnLeft()
        end
        turtle.turnLeft()
        turtle.turnLeft()
        
        -- order swapped here as we are going in the opposite direction
        extraTurtle.refuelToMin(Length, isNotWood)
        for _ = 1,Length do
            turtle.turnRight()
            if tryChopTree() then
                plantSapling()
                TreesChopped = TreesChopped + 1
            end
            turtle.turnLeft()
            extraTurtle.refuelToMin(1, isNotWood)
            extraTurtle.tolerantMove("forward")
        end

        turtle.turnRight()
        turtle.turnRight()
        local wh = service()
        WoodHarvested = WoodHarvested + wh
        printReport()
        sleep(120)
    end
end

if Length == nil then
    harvestOne()
else
    harvestRow()
end
