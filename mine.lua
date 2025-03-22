--[[
The mine program mines a lattice of 1x2 tunnels at constant height while placing
torches to keep them lit. The tunnels are one block wide and two blocks tall.
Each tunnel is made of segments (along the first dimension, each of which are
eight blocks long), and slices (along the second dimension, and are spaced every
five blocks to ensure coverage).
]]

local argv = { ... }
if #argv ~= 1 and #argv ~= 3 then
    print("Usage: mine <n segments> [<n slices> <initial direction>]")
    return
end

NSegments = tonumber(argv[1])
if NSegments < 1 then
    print("n segments must be positive")
    return
end

if #argv == 3 then
    NSlices = tonumber(argv[2])
    if NSlices < 1 then
        print("n slices must be positive")
        return
    end

    InitialDirection = argv[3]
    if InitialDirection ~= "left" and InitialDirection ~= "right" then
        print("initial direction must be left or right")
        return
    end
else
    NSlices = 1
    InitialDirection = nil
end

SegmentLength = 8

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

local function tolerantMove(direction, n)
    local functions = {
        down=turtle.down,
        up=turtle.up,
        forward=turtle.forward,
        back=turtle.back,
    }
    local f = functions[direction]
    if f == nil then return end
    if n == nil then n = 1 end
    for k = 1,n do
        while not f() do sleep(1) end
    end
end

local function gravityDig()
    local success, data = turtle.inspect()
    if not success then return end
    -- avoid mining diamond ore so that it can be mined with silk touch or
    -- fortune
    if data.name == "minecraft:diamond_ore" then
        success, data = turtle.inspect()
        while success do sleep(1) end
        return
    end
    while turtle.dig() do
        sleep(0.5)
    end
end

local function safeDigDown()
    local success, data = turtle.inspectDown()
    if not success then return end
    if data.name == "minecraft:diamond_ore" then
        success, data = turtle.inspect()
        while success do sleep(1) end
        return
    end
    turtle.digDown()
end

local function placeTorch()
    local torchSlot = 0
    for n = 1,16 do
        turtle.select(n)
        local data = turtle.getItemDetail()
        if data ~= nil and data.name == "minecraft:torch" then
            torchSlot = n
            break
        end
    end
    if torchSlot == 0 then return end
    turtle.select(torchSlot)
    --[[
    try and place a torch below the turtle
    if this fails, move down to place a cobblestone block to place the torch on
    ]]
    if not turtle.placeDown() then
        tolerantMove("down")
        for n = 1,16 do
            turtle.select(n)
            local data = turtle.getItemDetail()
            if data ~= nil and data.name == "minecraft:cobblestone" then
                turtle.placeDown()
                break
            end
        end
        tolerantMove("up")
        turtle.select(torchSlot)
        -- if this doesn't work for some reason, oh well
        turtle.placeDown()
    end
end

local function mine(n)
    if n == nil then n = 1 end
    for k = 1,n do
        gravityDig()
        tolerantMove("forward")
        safeDigDown()
    end
end

local function mineSegment()
    -- calculate needed fuel for this leg and refuel
    refuelToMin(SegmentLength)
    -- start by mining SegmentLength 1x2 tunnel
    mine(SegmentLength)
    -- now place a torch and then dig the connecting points either side
    refuelToMin(2)
    placeTorch()
    turtle.turnLeft()
    local success, data = turtle.inspect()
    if success then
        refuelToMin(4)
        mine(2)
        tolerantMove("back", 2)
    end

    turtle.turnRight()
    turtle.turnRight()

    local success, _ = turtle.inspect()
    if success then
        refuelToMin(4)
        mine(2)
        tolerantMove("back", 2)
    end

    turtle.turnLeft()
end

local function mineSegments()
    for n = 1,NSegments do
        print("Now mining segment " .. n .. " of " .. NSegments .. ".")
        mineSegment()
    end
end

local function nextSegment(direction)
    local turns = {
        right=turtle.turnRight,
        left=turtle.turnLeft,
    }
    local turn = turns[direction]
    if turn == nil then return end
    turn()
    mine(5)
    tolerantMove("back", 2)
    turn()
    placeTorch()
end

local function mineSlices()
    local currentDirection = InitialDirection
    local nextDirection = {
        left="right",
        right="left",
    }

    if NSlices == 1 then
        mineSegments()
        return
    end
    for k = 1,NSlices do
        print("Now mining slice " .. k .. " of " .. NSlices .. ".")
        mineSegments()
        nextSegment(currentDirection)
        currentDirection = nextDirection[currentDirection]
    end
end

local function ensureRightHeight()
    local successDown, dataDown = turtle.inspectDown()
    local successUp, _ = turtle.inspectUp()
    if successUp and not successDown then return true end
    if successDown and not successUp then
        refuelToMin(1)
        turtle.up()
        return true
    end
    if
        successUp
        and successDown
        and (
            dataDown.name == "minecraft:torch"
            or dataDown.name == "ComputerCraft:CC-Peripheral"
        )
    then
        return true
    end
end

if not ensureRightHeight() then
    print("Unable to determine correct level for turtle")
    return
end
mineSlices()
