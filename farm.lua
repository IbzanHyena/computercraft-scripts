local argv = { ... }

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

-- construct a Hamiltonian cycle of the graph
if Length % 2 == 1 then
    print("Length must be even.")
    return
end

Turns = {}
for row = 1,Length do
    Turns[row] = {}
    local leftCoordinate
    if row == 1 or row == Length then
        leftCoordinate = 1
    else
        leftCoordinate = 2
    end
    local leftSideTurn
    if row == 1 or row == Length then
      leftSideTurn = "R"
    else
        leftSideTurn = "L"
    end

    Turns[row][leftCoordinate] = leftSideTurn
    Turns[row][Width] = "R"
end

local function refuelToMin(amount)
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" or amount <= fuelLevel then
        return
    end

    local needed = amount - fuelLevel
    while needed > 0 do
        for n = 1,16 do
            if turtle.getItemCount(n) > 0 then
                turtle.select(n)
                turtle.refuel(1)
                needed = amount - turtle.getFuelLevel()
            end
        end
    end
end

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

local function find(item)
    for n = 1,16 do
        local detail = turtle.getItemDetail(n)
        if detail ~= nil and detail.name == item then
            return n
        end
    end
end

local function harvest()
    local success, crop = check()
    if not success then return end
    turtle.digDown()
    local slot = find(BlockToItemNames[crop])
    if slot ~= nil then
       turtle.select(slot)
       turtle.placeDown()
    end
end

local function checkGrid()
    local x, y = 1, 1
    local currentDirection = "N"
    local dx = {N=1, E=0, S=-1, W=0}
    local dy = {N=0, E=1, S=0, W=-1}
    local leftTurns = {N="W", E="N", S="E", W="S"}
    local rightTurns = {N="E", E="S", S="W", W="N"}
    local originTime = os.clock()
    refuelToMin(Length * Width)
    while true do
        harvest()
        turtle.forward()
        x = x + dx[currentDirection]
        y = y + dy[currentDirection]
        local turn = Turns[x][y]
        if turn == "L" then
            turtle.turnLeft()
            currentDirection = leftTurns[currentDirection]
        elseif turn == "R" then
            turtle.turnRight()
            currentDirection = rightTurns[currentDirection]
        end
        if x == 1 and y == 1 then
           local currentTime = os.clock()
           local sleepTime = math.max(0, IterationTime - (currentTime - originTime))
           sleep(sleepTime)
           refuelToMin(Length * Width)
           originTime = os.clock()
        end
    end
end

checkGrid()
