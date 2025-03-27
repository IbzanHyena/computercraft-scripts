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

if Length == 1 and Depth == 1 then
    extraTurtle.refuelToMin(Depth)
    for i = 1,Depth do
        turtle.digDown()
        extraTurtle.tolerantMove("down")
    end
elseif Length == 1 then
    turtle.turnRight()
    for i = 1,Depth do
        extraTurtle.refuelToMin(Width)
        for i = 1,Width do
            turtle.digDown()
            extraTurtle.tolerantMove("forward")
        end
        turtle.turnRight()
        turtle.turnRight()
        extraTurtle.tolerantMove("down")
    end
elseif Width == 1 then
    for i = 1,Depth do
        extraTurtle.refuelToMin(Length)
        for i = 1,Length do
            turtle.digDown()
            extraTurtle.tolerantMove("forward")
        end
        turtle.turnRight()
        turtle.turnRight()
        extraTurtle.tolerantMove("down")
    end
elseif (Length % 2 == 0) or (Width % 2 == 0) then
    local path = extraTurtle.GridHamiltonianCycle:new(Length, Width)
    for i = 1,Depth do
        extraTurtle.refuelToMin(Length * Width)
        path:walk(turtle.digDown)
        extraTurtle.refuelToMin(1)
        extraTurtle.tolerantMove("down")
    end
else
    local path = extraTurtle.GridPath:new(Length, Width)
    local inReverse = false
    for i = 1,Depth do
        extraTurtle.refuelToMin(Length * Width)
        path:walk(turtle.digDown, inReverse)
        extraTurtle.refuelToMin(1)
        extraTurtle.tolerantMove("down")
        turtle.turnRight()
        turtle.turnRight()
        inReverse = not inReverse
    end
end
