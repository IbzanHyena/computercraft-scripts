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
end

local state = {}
local digLayer

if Length == 1 and Depth == 1 then
    extraTurtle.refuelToMin(Depth)
    digLayer = function()
        turtle.digDown()
    end
elseif Length == 1 then
    turtle.turnRight()
    digLayer = function ()
        extraTurtle.refuelToMin(Width)
        for i = 1,Width-1 do
            turtle.digDown()
            extraTurtle.tolerantMove("forward")
        end
        turtle.digDown()
        turtle.turnRight()
        turtle.turnRight()
    end
elseif Width == 1 then
    digLayer = function ()
        extraTurtle.refuelToMin(Length)
        for i = 1,Length-1 do
            turtle.digDown()
            extraTurtle.tolerantMove("forward")
        end
        turtle.digDown()
        turtle.turnRight()
        turtle.turnRight()
    end
elseif (Length % 2 == 0) or (Width % 2 == 0) then
    local path = extraTurtle.GridHamiltonianCycle:new(Length, Width)
    digLayer = function ()
        extraTurtle.refuelToMin(Length * Width)
        path:walk(turtle.digDown)
    end
else
    local path = extraTurtle.GridPath:new(Length, Width)
    digLayer = function (s)
        extraTurtle.refuelToMin(Length * Width)
        path:walk(turtle.digDown, s.inReverse)
        turtle.digDown()
        turtle.turnRight()
        turtle.turnRight()
        s.inReverse = not s.inReverse
    end
    state.inReverse = false
end

local startTime = os.clock()
for i = 1,Depth do
    digLayer(state)
    extraTurtle.refuelToMin(1)
    extraTurtle.tolerantMove("down")
    local now = os.clock()
    print("Completed layer " .. i .. "/" .. Depth)
    print("Elapsed time: " .. (now - startTime) .. " s (" .. ((now - startTime) / i) .. " s/layer)")
    print("Estimated remaining time: " .. ((now - startTime) / i) * (Depth - i) .. " s")
end
