local argv = { ... }

if not os.loadAPI("/apis/extraTurtle") then
    print("Failed to load extraTurtle API")
end

if #argv ~= 3 then
    print("Usage: farm <length> <width> <depth>")
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

if Length == 1 then
    turtle.turnRight()
    for i = 1,Depth do
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
        for i = 1,Length do
            turtle.digDown()
            extraTurtle.tolerantMove("forward")
        end
        turtle.turnRight()
        turtle.turnRight()
        extraTurtle.tolerantMove("down")
    end
else
    for i = 1,Depth do
        extraTurtle.walkGrid(Length, Width, turtle.digDown)
        extraTurtle.refuelToMin(1)
        extraTurtle.tolerantMove("down")
    end
end
