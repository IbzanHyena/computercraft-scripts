local argv = { ... }

if not os.loadAPI("/apis/extraTurtle") then
    print("Failed to load extraTurtle API")
end

if #argv ~= 3 then
    print("Usage: lwdexcavate <length> <width> <depth>")
    return
end

Length = tonumber(argv[1])
if Length == nil or Length < 1 then
    print("Length must be positive.")
    return
end

Width = tonumber(argv[2])
if Width == nil or Width < 1 then
    print("Width must be positive.")
    return
end

Depth = tonumber(argv[3])
if Depth == nil or Depth < 1 then
    print("Depth must be positive")
    return
end

local digFunctions = {
    turtle.digDown,
    turtle.dig,
    turtle.digUp,
}

local function dig(n)
    for i = 1,n do
        digFunctions[i]()
    end
end

local state = {}
local digLayer

if Length == 1 and Depth == 1 then
    extraTurtle.refuelToMin(Depth)
    digLayer = function (toDig)
        -- regardless of what toDig is, we can only dig one block down
        turtle.digDown()
        return 1
    end
elseif Length == 1 then
    turtle.turnRight()
    digLayer = function (toDig)
        extraTurtle.refuelToMin(Width)
        for i = 1,Width-1 do
            dig(toDig)
            extraTurtle.tolerantMove("forward")
        end
        turtle.digDown()
        turtle.turnRight()
        turtle.turnRight()
        return toDig
    end
elseif Width == 1 then
    digLayer = function (toDig)
        extraTurtle.refuelToMin(Length)
        for i = 1,Length-1 do
            dig(toDig)
            extraTurtle.tolerantMove("forward")
        end
        turtle.digDown()
        turtle.turnRight()
        turtle.turnRight()
        return toDig
    end
elseif (Length % 2 == 0) or (Width % 2 == 0) then
    local path = extraTurtle.GridHamiltonianCycle:new(Length, Width)
    digLayer = function (toDig)
        extraTurtle.refuelToMin(Length * Width)
        path:walk(function () dig(toDig) end)
        return toDig
    end
else
    local path = extraTurtle.GridPath:new(Length, Width)
    digLayer = function (toDig, s)
        extraTurtle.refuelToMin(Length * Width)
        path:walk(function () dig(toDig) end, s.inReverse)
        turtle.digDown()
        turtle.turnRight()
        turtle.turnRight()
        s.inReverse = not s.inReverse
        return toDig
    end
    state.inReverse = false
end

local startTime = os.clock()
local remaining, completed = Depth, 0
local first = true
while remaining > 0 do
    -- dig up to three layers: below, equal, above (in that order)
    local toDig = math.min(remaining, 3)
    if toDig == 2 then
        -- we must move down an extra block so that the equal level is filled
        extraTurtle.refuelToMin(1)
        turtle.digDown()
        extraTurtle.tolerantMove("down")
    elseif toDig == 3 then
        -- we must move down two extra blocks so that equal and above levels are filled
        extraTurtle.refuelToMin(2)
        turtle.digDown()
        extraTurtle.tolerantMove("down")
        turtle.digDown()
        extraTurtle.tolerantMove("down")
    end
    local dug = digLayer(toDig, state)
    remaining = remaining - dug
    completed = completed + dug

    -- we always move down by 1 because the turtle can only dig out one block below it
    extraTurtle.refuelToMin(1)
    extraTurtle.tolerantMove("down")

    local now = os.clock()
    if not first then
        print("----------")
    else
        first = false
    end

    local elapsedTimePerLayer = (now - startTime) / completed
    print("Completed layer " .. completed .. "/" .. Depth)
    print("Elapsed time: " .. (now - startTime) .. " s (" .. elapsedTimePerLayer .. " s/layer)")
    print("Estimated remaining time: " .. elapsedTimePerLayer * remaining .. " s")
end
