local argv = { ... }

if not os.loadAPI("/apis/extraTurtle") then
    print("Failed to load extraTurtle API")
end

if #argv ~= 2 then
    print("Usage: farm <length> <width>")
    return
end

Length = tonumber(argv[1])
if Length == nil or Length < 2 then
    print("Length must be >= 2.")
    return
end

Width = tonumber(argv[2])
if Width == nil or Width < 2 then
    print("Width must be >= 2.")
    return
end

IterationTime = 300 -- seconds

FinishedStates = {}
FinishedStates["minecraft:potatoes"] = 7
FinishedStates["minecraft:carrots"] = 7

BlockToItemNames = {}
BlockToItemNames["minecraft:potatoes"] = "minecraft:potato"
BlockToItemNames["minecraft:carrots"] = "minecraft:carrot"

local function check()
    local success, data = turtle.inspectDown()
    if not success then return false, nil end
    for k, v in pairs(FinishedStates) do
        if data.name == k and data.metadata == v then
            return true, data.name
        end
    end
    return false, nil
end

local function harvest()
    local success, crop = check()
    if not success then return end
    turtle.digDown()
    local slot = extraTurtle.find(BlockToItemNames[crop])
    if slot ~= nil then
       turtle.select(slot)
       turtle.placeDown()
    end
end

local function dumpCrops()
    for n = 2,16 do
        turtle.select(n)
        turtle.drop()
    end
end

local function getFuel()
    turtle.select(1)
    local capacity = 64 - turtle.getItemCount()
    turtle.suck(capacity)
end

local originTime = os.clock()
local path = extraTurtle.GridHamiltonianCycle:new(Length, Width)
while true do
    extraTurtle.refuelToMin(Length * Width)
    path:walk(harvest)
    turtle.turnLeft()
    dumpCrops()
    turtle.turnLeft()
    getFuel()
    turtle.turnRight()
    turtle.turnRight()
    local currentTime = os.clock()
    local sleepTime = math.max(0, IterationTime - (currentTime - originTime))
    sleep(sleepTime)
    originTime = os.clock()
end
